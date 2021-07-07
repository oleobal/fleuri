module fluri;

import std.algorithm.iteration;
import std.array;
import std.random;
import std.traits;
import std.conv;

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
		return num.to!string~"/"~denum.to!string;
	}
}

enum LetterSet
{
	ALPHA = "abcdefghijklmnopqrstuvwxyz".to!(dchar[]),
	NUM = "0123456789".to!(dchar[]),
	ALPHANUM = "abcdefghijklmnopqrstuvwxyz0123456789".to!(dchar[]),
	EXTENDED = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_".to!(dchar[]), // AKA youtube
}


enum IdentGeneratorRole
{
	ROOT,
	NODE,
	LEAF,
}


class IdentGenerator
{
	IdentGeneratorRole role;
	dchar letter;
	
	IdentGenerator[] children;
	
	bool[dchar] letters;
	
	this(int length, dchar[] choices)
	{
		assert(length>0);
		assert(choices.length>0);
		role = IdentGeneratorRole.ROOT;
		
		if (length == 1)
			foreach (c;choices)
				letters[c] = false;
		else
			foreach (c;choices)
				children~=(new IdentGenerator(choices, c, length-1));
	}
	
	this(dchar[] choices, dchar letter, int digitsLeft)
	{
		this.letter = letter;
		if (digitsLeft>0)
		{
			role = IdentGeneratorRole.NODE;
			foreach (c;choices)
				children~=(new IdentGenerator(choices, c, digitsLeft-1));
		}
		else
		{
			role = IdentGeneratorRole.LEAF;
			foreach (c;choices)
				letters[c] = false;
		}
		
	}
	
	
	dstring generate()
	{
		if (children.length>0)
		{
			Count[] counts = children.map!(c=>c.spaceTaken).array;
			auto proportions = counts.map!(c=>c.denum-c.num).array;
			auto choice = dice(proportions);
			if (role == IdentGeneratorRole.ROOT)
				return children[choice].generate();
			else
				return letter ~ children[choice].generate();
		}
		else
		{
			dchar[] availableLetters = letters.byKeyValue.filter!(it=>!it.value).map!(it=>it.key).array;
			dchar chosenLetter = choice(availableLetters);
			letters[chosenLetter] = true;
			return [chosenLetter];
		}
	}
	
	Count spaceTaken()
	{
		if (children.length>0)
		{
			Count c = Count(0,0);
			foreach(child;children)
			{
				c = c + child.spaceTaken;
			}
			return c;
		}
		else
		{
			Count c = Count(0,letters.length);
			foreach(l;letters.byValue)
			{
				if(l) c.num += 1;
			}
			return c;
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
		result ~= ""~role.to!string;
		if (role == IdentGeneratorRole.NODE)
			result[0] ~= " "~letter.to!string;
		if (letters.length > 0)
			result[0] ~= " "~spaceTaken.asFraction~" "~letters.byKeyValue.filter!(it=>it.value).map!(it=>it.key).to!string;
		if (children.length>0)
			result~= "Children:";
		foreach	(c;children)
		{
			auto s = c.debugTree.split("\n").array;
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
		return result.join("\n");
	}
}

unittest
{
	import std.stdio;
	import std.conv;
	
	auto gen = new IdentGenerator(3, "abc".to!(dchar[]));
	/+
	gen.length.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.spaceTaken.writeln;
	gen.debugTree.writeln;
	+/
	gen = new IdentGenerator(3, LetterSet.EXTENDED);
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.generate.writeln;
	gen.spaceTaken.writeln;
}