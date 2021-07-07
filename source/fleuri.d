module fleuri;

import std.algorithm.iteration:map,filter,sum;
import std.algorithm.mutation:remove;

import std.array;
import std.random;
import std.traits;
import std.conv;
import std.math;

/// "x out of y"
struct Count
{
	long num;
	long denum;
	
	Count opBinary(string op)(Count rhs)
	{
		static if (op == "+") return Count(num+rhs.num, denum+rhs.denum);
		else static assert(0, "Operator "~op~" not implemented");
	}
	
	string asFraction()
	{
		return num.to!string~"/"~denum.to!string~" ("~(num*100/denum).to!string~"%)";
	}
}

enum LetterSet
{
	ALPHA = "abcdefghijklmnopqrstuvwxyz".to!(dchar[]),
	NUM = "0123456789".to!(dchar[]),
	ALPHANUM = "abcdefghijklmnopqrstuvwxyz0123456789".to!(dchar[]),
	EXTENDED = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_".to!(dchar[]), // AKA youtube
}


class NoSpaceLeftException : Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

enum IdentGeneratorRole
{
	ROOT,
	NODE,
	LEAF,
}


class IdentGeneratorNode
{
	IdentGeneratorRole role;
	/// what letter this node is
	dchar letter;
	/// how many digits (= tree levels) are left after this node
	int digitsLeft;
	
	IdentGeneratorNode[dchar] children;
	/// in the same order as for dchar[] choices
	ulong[] childrenFreeSpace;
	
	/// if a leaf, used letters are inserted (basically a set)
	bool[dchar] letters;
	/// all possible letter choices (shared reference for every node in the tree, if all works well)
	dchar[] choices;
	
	this(ref dchar[] choices, dchar letter, int digitsLeft, bool eagerInit=false)
	{
		this.choices = choices;
		this.letter = letter;
		this.digitsLeft=digitsLeft;
		if (digitsLeft>1)
		{
			role = IdentGeneratorRole.NODE;
			foreach (c;choices)
			{
				childrenFreeSpace~= pow(choices.length, digitsLeft-1);
				if (eagerInit)
					children[c] = new IdentGeneratorNode(choices, c, digitsLeft-1, eagerInit);
			}
		}
		else
		{
			role = IdentGeneratorRole.LEAF;
		}
	}
	
	
	dstring generate()
	{
		if (role == IdentGeneratorRole.ROOT || role == IdentGeneratorRole.NODE)
		{
			
			try
			{
				auto choice = dice(childrenFreeSpace);
				childrenFreeSpace[choice]--; // should never fail
				if (!(choices[choice] in children))
					children[choices[choice]] = new IdentGeneratorNode(choices, choices[choice], digitsLeft-1);
				if (role == IdentGeneratorRole.ROOT)
					return children[choices[choice]].generate();
				else
					return letter ~ children[choices[choice]].generate();
			}
			catch (Exception e)
			{
				if (childrenFreeSpace.sum == 0)
					throw new NoSpaceLeftException("No space left");
				throw e;
			}
		}
		else
		{
			auto availableLetters = choices.dup.remove!(it=>it in letters);
			if (availableLetters.length == 0)
				throw new NoSpaceLeftException("No space left");
			dchar chosenLetter = choice(availableLetters);
			letters[chosenLetter] = true;
			return [letter,chosenLetter];
		}
	}
	
	/++
	 + Computes the number of IDs vs the total available number
	 + returns incorrect results with lazy init (FIXME?)
	 + is relatively expensive with eager init
	 +/
	Count spaceTaken()
	{
		if (children.length>0)
		{
			Count c = Count(0,0);
			foreach(child;children)
				c = c + child.spaceTaken;
			return c;
		}
		else
		{
			return Count(letters.length,choices.length);
		}
	}
	
	ulong length()
	{
		if (role == IdentGeneratorRole.ROOT)
			return children[0].length;
		if (role == IdentGeneratorRole.NODE)
			return children[0].length+1;
		return 1;
	}
	
	string debugTree()
	{
		string[] result;
		result ~= role.to!string;
		result[0] ~= " "~letter.to!string;
		if (letters.length > 0)
			result[0] ~= " "~spaceTaken.asFraction~" "~letters.byKeyValue.filter!(it=>it.value).map!(it=>it.key).to!string;
		if (role == IdentGeneratorRole.ROOT || role == IdentGeneratorRole.NODE)
		{
			result~= "Children:";
			foreach (c;choices)
			{
				if (c in children)
				{
					auto s = children[c].debugTree.split("\n").array;
					if (s.length == 1)
						result~= " ━"~s[0];
					else
					{
						result ~= " ┏"~s[0];
						foreach(l;s[1..$-1])
						{
							result ~= " ┃"~l;
						}
						result ~= " ┗"~s[$-1];
					}
				}
				else
				{
					result ~= " ━Uninitialized child";
				}
			}
		}
		return result.join("\n");
	}
}


class IdentGenerator : IdentGeneratorNode
{
	dchar[] choices;
	
	this(int length, dchar[] choices, bool eagerInit=false)
	{
		assert(length>0);
		assert(choices.length>0);
		super(choices, dchar.init, length, eagerInit);
		role = IdentGeneratorRole.ROOT;
	}
	
}


unittest
{
	import std.stdio:writeln;
	import std.conv:to;
	import core.time:MonoTime, Duration;
	import std.typecons:Tuple,tuple;
	import std.format:format;
	
	Tuple!(string, Duration)[] durMeasures;
	
	void takeMeasure(string desc, void delegate() d, int iters=1)
	{
		auto start = MonoTime.currTime;
		for (auto i=0;i<iters;i++)
			d();
		auto end = MonoTime.currTime;
		durMeasures ~= tuple(desc, (end-start)/iters);
	}
	
	IdentGenerator gen;
	
	
	/+
	gen = new IdentGenerator(3, "abc".to!(dchar[]));
	gen.length.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.spaceTaken.writeln;
	gen.debugTree.writeln;
	+/
	
	takeMeasure("6,   lazy,       init", { gen = new IdentGenerator(6, LetterSet.ALPHA); }, 10);
	takeMeasure("6,   lazy,   generate", { gen.generate; }, 1000);
	// takeMeasure("6, lazy,  spaceTaken", { gen.spaceTaken; });
	takeMeasure("6,  eager,       init", { gen = new IdentGenerator(6, LetterSet.ALPHA, true); });
	takeMeasure("6,  eager,   generate", { gen.generate; }, 1000);
	// takeMeasure("6, eager, spaceTaken", { gen.spaceTaken; });
	
	takeMeasure("11, lazy,        init", { gen = new IdentGenerator(11, LetterSet.EXTENDED); });
	takeMeasure("11, lazy,    generate", { gen.generate; }, 1000);
	
	foreach(e;durMeasures)
		writeln("%-50s %-50s".format(e[0], e[1]));
}