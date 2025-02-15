open Standard;
open AlcoJest;

let suite =
  suite("String", () => {
    open String;

    testAll("ofChar", [('a', "a"), ('z', "z"), (' ', " "), ('\n', "\n")], ((char, string)) => {
      expect(ofChar(char)) |> toEqual(Eq.string, string)
    });

    describe("ofArray", () => {
      test("creates an empty string from an empty array", () => {
        expect(ofArray([||])) |> toEqual(Eq.string, "")
      })

      test("creates a string of characters", () => {
        expect(ofArray([|'K','u','b','o'|])) |> toEqual(Eq.string, "Kubo")
      });

      test("creates a string of characters", () => {
        expect(ofArray([|' ', '\n', '\t'|])) |> toEqual(Eq.string, " \n\t")
      });
    });

    describe("ofList", () => {
      test("creates an empty string from an empty array", () => {
        expect(ofList([])) |> toEqual(Eq.string, "")
      });

      test("creates a string of characters", () => {
        expect(ofList(['K', 'u', 'b', 'o'])) |> toEqual(Eq.string, "Kubo")
      });

      test("creates a string of characters", () => {
        expect(ofList([' ', '\n', '\t'])) |> toEqual(Eq.string, " \n\t")
      });
    });

    describe("repeat", () => {
      test("returns an empty string for count zero", () => {
        expect(repeat("bun", ~count=0)) |> toEqual(Eq.string, "")
      })

      test("raises for negative count", () => {
        expect(() => repeat("bun", ~count=-1)) |> toThrow
      });

      test("returns the input string repeated count times", () => {
        expect(repeat("bun", ~count=3)) |> toEqual(Eq.string, "bunbunbun")
      });
    });

    describe("initialize", () => {
      test("returns an empty string for count zero", () => {
        expect(initialize(0, ~f=Fun.constant('A'))) |> toEqual(Eq.string, "")
      });

      test("raises for negative count", () => {
        expect(() => initialize(-1, ~f=Fun.constant('A'))) |> toThrow
      });

      test("returns the input string repeated count times", () => {
        expect(initialize(3, ~f=Fun.constant('A'))) |> toEqual(Eq.string, "AAA")
      });
    });

    describe("isEmpty", () => {
      test("true for zero length string", () => {
        expect(isEmpty("")) |> toEqual(Eq.bool, true)
      })

      testAll("false for length > 0 strings", ["abc", " ", "\n"], string => {
        expect(isEmpty(string)) |> toEqual(Eq.bool, false)
      })
    })

    test("length empty string", () => {
      expect(String.length("")) |> toEqual(Eq.int, 0)
    });
    test("length", () => {
      expect(String.length("123")) |> toEqual(Eq.int, 3)
    });
    test("reverse empty string", () => {
      expect(String.reverse("")) |> toEqual(Eq.string, "")
    });
    test("reverse", () => {
      expect(String.reverse("stressed")) |> toEqual(Eq.string, "desserts")
    });

    test("toArray", () => {
      expect(String.toArray("Standard"))
      |> toEqual(Eq.(array(char)), [|'S', 't', 'a', 'n', 'd', 'a', 'r', 'd'|])
    });

    test("toList", () => {
      expect(String.toList("Standard")) |> toEqual(Eq.(list(char)), ['S', 't','a','n','d','a','r','d']);
    })
  });
