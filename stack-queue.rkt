#lang dssl2

# HW2: Stacks and Queues

import ring_buffer

interface STACK[T]:
    def push(self, element: T) -> NoneC
    def pop(self) -> T
    def empty?(self) -> bool?

# Defined in the `ring_buffer` library; copied here for reference.
# Do not uncomment! or you'll get errors.
# interface QUEUE[T]:
#     def enqueue(self, element: T) -> NoneC
#     def dequeue(self) -> T
#     def empty?(self) -> bool?

# Linked-list node struct (implementation detail):
struct _cons:
    let data
    let next: OrC(_cons?, NoneC)

###
### ListStack
###

class ListStack[T] (STACK):

    # Any fields you may need can go here.
    let stack: OrC(NoneC, _cons?)

    # Constructs an empty ListStack.
    def __init__ (self):
        self.stack = None

    def push(self, element: T):
        self.stack = _cons(element, self.stack)
        
    def pop(self):
        if self.empty?():
            error ("empty stack")
        let ans = self.stack.data
        self.stack = self.stack.next
        return ans
        
    def empty?(self):
        if self.stack is None:
            return True
        return False
        
    # Other methods you may need can go here.

test "woefully insufficient":
    let s = ListStack()
    s.push(2)
    assert s.pop() == 2
    
test "ListStack empty? on new stack":
    let s = ListStack()
    assert s.empty?() == True

test "ListStack push push pop pop is LIFO":
    let s = ListStack()
    s.push(1)
    s.push(2)
    assert s.pop() == 2
    assert s.pop() == 1
    assert s.empty?() == True

test "ListStack push pop push pop still works":
    let s = ListStack()
    s.push(10)
    assert s.pop() == 10
    assert s.empty?() == True
    s.push(20)
    assert s.pop() == 20
    assert s.empty?() == True

test "ListStack pop on empty raises error":
    let s = ListStack()
    assert_error s.pop()

test "ListStack pop after emptying raises error":
    let s = ListStack()
    s.push(5)
    assert s.pop() == 5
    assert s.empty?() == True
    assert_error s.pop()

###
### ListQueue
###

class ListQueue[T] (QUEUE):

    # Any fields you may need can go here.
    let head: OrC(NoneC, _cons?)
    let tail: OrC(NoneC, _cons?)

    # Constructs an empty ListQueue.
    def __init__ (self):
        self.head = None
        self.tail = None
        
    def enqueue(self, element: T):
        let new = _cons(element, None)
        if self.empty?():
            self.head = new
            self.tail = new
        else:
            self.tail.next = new
            self.tail = self.tail.next
        
    def dequeue(self):
        if self.empty?(): 
            error ("empty queue")
        let ans = self.head.data
        if self.head.next is None:
            self.head = None
            self.tail = None
            return ans
        else:
            self.head = self.head.next
            return ans
        
    def empty?(self):
        if self.head is None and self.tail is None:
            return True
        return False

    # Other methods you may need can go here.

test "woefully insufficient, part 2":
    let q = ListQueue()
    q.enqueue(2)
    assert q.dequeue() == 2
    
test "ListQueue empty? on new queue":
    let q = ListQueue()
    assert q.empty?() == True

test "ListQueue enqueue dequeue single":
    let q = ListQueue()
    q.enqueue(7)
    assert q.empty?() == False
    assert q.dequeue() == 7
    assert q.empty?() == True

test "ListQueue FIFO order for three items":
    let q = ListQueue()
    q.enqueue(1)
    q.enqueue(2)
    q.enqueue(3)
    assert q.dequeue() == 1
    assert q.dequeue() == 2
    assert q.dequeue() == 3
    assert q.empty?() == True

test "ListQueue alternating enqueue and dequeue":
    let q = ListQueue()
    q.enqueue(1)
    assert q.dequeue() == 1
    q.enqueue(2)
    q.enqueue(3)
    assert q.dequeue() == 2
    q.enqueue(4)
    assert q.dequeue() == 3
    assert q.dequeue() == 4
    assert q.empty?() == True

test "ListQueue dequeue on empty raises error":
    let q = ListQueue()
    assert_error q.dequeue()

test "ListQueue reuse after becoming empty":
    let q = ListQueue()
    q.enqueue(9)
    assert q.dequeue() == 9
    assert q.empty?() == True
    q.enqueue(10)
    q.enqueue(11)
    assert q.dequeue() == 10
    assert q.dequeue() == 11
    assert q.empty?() == True

###
### Playlists
###

struct song:
    let title: str?
    let artist: str?
    let album: str?

# Enqueue five songs of your choice to the given queue, then return the first
# song that should play.
def fill_playlist (q: QUEUE!):
    if not q.empty?():
        error ("non-empty queue")
    q.enqueue(song("Marvins Room", "Drake", "Take Care"))
    q.enqueue(song("Sticky", "Drake", "Honestly Nevermind"))
    q.enqueue(song("Crying in Chanel", "Drake", "$ome $exy $ongs 4 U"))
    q.enqueue(song("Passionfruit", "Drake", "More Life"))
    q.enqueue(song("Ghost Town", "Kanye West", "ye"))
    q.dequeue()

test "ListQueue playlist":
    let q = ListQueue()
    let first = fill_playlist(q)
    assert first.title == "Marvins Room"
    assert first.artist == "Drake"
    assert first.album == "Take Care"
    

test "fill_playlist errors on non empty queue":
    let q = ListQueue()
    q.enqueue(song("X", "Y", "Z"))
    assert_error fill_playlist(q)

test "fill_playlist ListQueue returns first and leaves rest in order":
    let q = ListQueue()
    let first = fill_playlist(q)
    assert first.title == "Marvins Room"
    assert q.dequeue().title == "Sticky"
    assert q.dequeue().title == "Crying in Chanel"
    assert q.dequeue().title == "Passionfruit"
    assert q.dequeue().title == "Ghost Town"
    assert q.empty?() == True

# To construct a RingBuffer: RingBuffer(capacity)
test "RingBuffer playlist":
    let q = RingBuffer(5)

    let first = fill_playlist(q)

    assert first.title == "Marvins Room"
    assert first.artist == "Drake"
    assert first.album == "Take Care"

    assert q.dequeue().title == "Sticky"
    assert q.dequeue().title == "Crying in Chanel"
    assert q.dequeue().title == "Passionfruit"
    assert q.dequeue().title == "Ghost Town"

    assert q.empty?() == True

test "fill_playlist RingBuffer returns first and leaves rest in order":
    let q = RingBuffer(5)
    let first = fill_playlist(q)
    assert first.title == "Marvins Room"
    assert q.dequeue().title == "Sticky"
    assert q.dequeue().title == "Crying in Chanel"
    assert q.dequeue().title == "Passionfruit"
    assert q.dequeue().title == "Ghost Town"
    assert q.empty?() == True

test "fill_playlist RingBuffer errors on non empty queue":
    let q = RingBuffer(5)
    q.enqueue(song("X", "Y", "Z"))
    assert_error fill_playlist(q)
