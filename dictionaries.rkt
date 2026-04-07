#lang dssl2

# HW3: Dictionaries

import sbox_hash

# Linked-list node struct (implementation detail):
struct _cons:
    let key
    let value
    let next: OrC(_cons?, NoneC)
    
# A signature for the dictionary ADT. The contract parameters `K` and
# `V` are the key and value types of the dictionary, respectively.
interface DICT[K, V]:
    # Returns the number of key-value pairs in the dictionary.
    def len(self) -> nat?
    # Is the given key mapped by the dictionary?
    # Notation: `key` is the name of the parameter. `K` is its contract.
    def mem?(self, key: K) -> bool?
    # Gets the value associated with the given key; calls `error` if the
    # key is not present.
    def get(self, key: K) -> V
    # Modifies the dictionary to associate the given key and value. If the
    # key already exists, its value is replaced.
    def put(self, key: K, value: V) -> NoneC
    # Modifes the dictionary by deleting the association of the given key.
    def del(self, key: K) -> NoneC
    # The following method allows dictionaries to be printed
    def __print__(self, print)


class AssociationList[K, V] (DICT):

    let _head
    let size
    #   ^ ADDITIONAL FIELDS HERE

    def __init__(self):
        self._head = None
        self.size = 0

    def len(self) -> nat?:
        return self.size
        
    def mem?(self, key: K) -> bool?:
        let current = self._head
        while current is not None:
            if current.key == key:
                return True
            current = current.next
        return False
        
    def get(self, key: K) -> V:
        let current = self._head
        while current is not None:
            if (current.key == key):
                return current.value
            current = current.next
        error ("key not found")
        
    def put(self, key: K, value: V) -> NoneC:
        let ans = _cons(key, value, self._head)
        let current = self._head
        if self.mem?(key):
            while current is not None:
                if (current.key == key):
                    current.value = value
                    return
                current = current.next
        else:
            self._head = ans
            self.size = self.size + 1
        
    def del(self, key: K) -> NoneC:
        let previous = None
        let current = self._head
    
        while current is not None:
            if current.key == key:
                if previous is None:
                    self._head = current.next
                else:
                    previous.next = current.next
                self.size = self.size - 1
                return
            previous = current
            current = current.next
             
        
    def __print__(self, print):
        print("#<object:AssociationList head=%p>", self._head)

    # Other methods you may need can go here.


test 'yOu nEeD MorE tEsTs':
    let a = AssociationList()
    assert not a.mem?('hello')
    a.put('hello', 5)
    assert a.len() == 1
    assert a.mem?('hello')
    assert a.get('hello') == 5

test "AssociationList empty? style basic mem on new dict":
    let a = AssociationList()
    assert a.len() == 0
    assert not a.mem?("hello")

test "AssociationList put get single":
    let a = AssociationList()
    a.put("hello", 5)
    assert a.len() == 1
    assert a.mem?("hello")
    assert a.get("hello") == 5

test "AssociationList get missing raises error":
    let a = AssociationList()
    assert_error a.get("missing")

test "AssociationList put put different keys":
    let a = AssociationList()
    a.put("a", 1)
    a.put("b", 2)
    assert a.len() == 2
    assert a.get("a") == 1
    assert a.get("b") == 2

test "AssociationList put update existing key":
    let a = AssociationList()
    a.put("a", 1)
    a.put("a", 9)
    assert a.len() == 1
    assert a.mem?("a")
    assert a.get("a") == 9

test "AssociationList del missing has no effect":
    let a = AssociationList()
    a.put("a", 1)
    a.del("zzz")
    assert a.len() == 1
    assert a.get("a") == 1

test "AssociationList del head":
    let a = AssociationList()
    a.put("a", 1)
    a.put("b", 2)
    a.del("b")
    assert a.len() == 1
    assert not a.mem?("b")
    assert a.get("a") == 1

test "AssociationList del non head":
    let a = AssociationList()
    a.put("a", 1)
    a.put("b", 2)
    a.put("c", 3)
    a.del("b")
    assert a.len() == 2
    assert a.get("a") == 1
    assert a.get("c") == 3
    assert not a.mem?("b")

test "AssociationList delete only item":
    let a = AssociationList()
    a.put("a", 1)
    a.del("a")
    assert a.len() == 0
    assert not a.mem?("a")
    assert_error a.get("a")

test "AssociationList reuse after delete":
    let a = AssociationList()
    a.put("a", 1)
    a.del("a")
    a.put("b", 2)
    assert a.len() == 1
    assert a.get("b") == 2

class HashTable[K, V] (DICT):
    let _hash
    let _size
    let _data
    let _nbuckets
    
    def __init__(self, nbuckets: nat?, hash: FunC[AnyC, nat?]):
        self._hash = hash
        self._size = 0
        self._nbuckets = nbuckets
        self._data = [None; nbuckets]

        let i = 0
        while i < nbuckets:
            self._data[i] = AssociationList()
            i = i + 1
        
    def len(self) -> nat?:
        return self._size

    def _bucket_index(self, key: K) -> nat?:
        return self._hash(key) % self._nbuckets

    def _bucket(self, key: K):
        return self._data[self._bucket_index(key)]
        
    def mem?(self, key: K) -> bool?:
        return self._bucket(key).mem?(key)
        
    def get(self, key: K) -> V:
        return self._bucket(key).get(key)

    def put(self, key: K, value: V) -> NoneC:
        let bucket = self._bucket(key)
        if not bucket.mem?(key):
            self._size = self._size + 1
        bucket.put(key, value)

    def del(self, key: K) -> NoneC:
        let bucket = self._bucket(key)
        if bucket.mem?(key):
            bucket.del(key)
            self._size = self._size - 1
        
    # This avoids trying to print the hash function, since it's not really
    # printable and isn’t useful to see anyway:
    def __print__(self, print):
        print("#<object:HashTable  _hash=... _size=%p _data=%p>",
              self._size, self._data)

# first_char_hasher(String) -> Natural
# A simple and bad hash function that just returns the ASCII code
# of the first character.
# Useful for debugging because it's easily predictable.
def first_char_hasher(s: str?) -> int?:
    if s.len() == 0:
        return 0
    else:
        return int(s[0])

test 'yOu nEeD MorE tEsTs, part 2':
    let h = HashTable(10, make_sbox_hash())
    assert not h.mem?('hello')
    h.put('hello', 5)
    assert h.len() == 1
    assert h.mem?('hello')
    assert h.get('hello') == 5

test "HashTable empty basic":
    let h = HashTable(8, make_sbox_hash())
    assert h.len() == 0
    assert not h.mem?("x")

test "HashTable put get single":
    let h = HashTable(8, make_sbox_hash())
    h.put("a", 1)
    assert h.len() == 1
    assert h.mem?("a")
    assert h.get("a") == 1

test "HashTable get missing raises error":
    let h = HashTable(8, make_sbox_hash())
    assert_error h.get("missing")

test "HashTable update existing key":
    let h = HashTable(8, make_sbox_hash())
    h.put("a", 1)
    h.put("a", 9)
    assert h.len() == 1
    assert h.mem?("a")
    assert h.get("a") == 9

test "HashTable del missing has no effect":
    let h = HashTable(8, make_sbox_hash())
    h.put("a", 1)
    h.del("zzz")
    assert h.len() == 1
    assert h.get("a") == 1

test "HashTable delete only item":
    let h = HashTable(8, make_sbox_hash())
    h.put("a", 1)
    h.del("a")
    assert h.len() == 0
    assert not h.mem?("a")
    assert_error h.get("a")

test "HashTable reuse after delete":
    let h = HashTable(8, make_sbox_hash())
    h.put("a", 1)
    h.del("a")
    h.put("b", 2)
    assert h.len() == 1
    assert h.get("b") == 2

test "HashTable collision handling with first_char_hasher":
    let h = HashTable(5, first_char_hasher)
    h.put("apple", 1)
    h.put("ant", 2)
    assert h.len() == 2
    assert h.mem?("apple")
    assert h.mem?("ant")
    assert h.get("apple") == 1
    assert h.get("ant") == 2

test "HashTable collision update with first_char_hasher":
    let h = HashTable(5, first_char_hasher)
    h.put("apple", 1)
    h.put("ant", 2)
    h.put("apple", 8)
    assert h.len() == 2
    assert h.get("apple") == 8
    assert h.get("ant") == 2

test "HashTable collision delete head of bucket":
    let h = HashTable(5, first_char_hasher)
    h.put("apple", 1)
    h.put("ant", 2)
    h.del("ant")
    assert h.len() == 1
    assert not h.mem?("ant")
    assert h.get("apple") == 1

test "HashTable collision delete non head of bucket":
    let h = HashTable(5, first_char_hasher)
    h.put("apple", 1)
    h.put("ant", 2)
    h.del("apple")
    assert h.len() == 1
    assert not h.mem?("apple")
    assert h.get("ant") == 2

test "HashTable different buckets":
    let h = HashTable(10, first_char_hasher)
    h.put("apple", 1)
    h.put("banana", 2)
    h.put("carrot", 3)
    assert h.len() == 3
    assert h.get("apple") == 1
    assert h.get("banana") == 2
    assert h.get("carrot") == 3


def compose_phrasebook(d: DICT!) -> DICT?:
    d.put("Takk", ["Thanks", "Tahk"])
    d.put("Fyrirgefðu", ["Excuse me", "Fi-rir-gyev-thu"])
    d.put("Því miður", ["I'm sorry", "Thvee mi-thur"])
    d.put("Varúð!", ["Look out!", "Va-rooth!"])
    d.put("Ég skil ekki", ["I don't understand", "Yeh skil eh-ki"])
    return d

test "AssociationList phrasebook":
    let a = AssociationList()
    let book = compose_phrasebook(a)
    assert book.len() == 5
    assert book.mem?("Takk")
    assert book.get("Takk")[1] == "Tahk"

test "HashTable phrasebook":
    let h = HashTable(10, first_char_hasher)
    let book = compose_phrasebook(h)
    assert book.len() == 5
    assert book.mem?("Ég skil ekki")
    assert book.get("Ég skil ekki")[1] == "Yeh skil eh-ki"
