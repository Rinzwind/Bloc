"
I can be used to convert OSWindow-level events to Morphic events.
So, that installing my instance as event handler for specific window would allow running Morphic World in it.

Later, the Morphic can be integrated with OSWindow API to avoid unnecessary conversion and thus eliminating the need in having this class.
"
Class {
	#name : #BlMorphicWorldEmbeddingEventHandler,
	#superclass : #BlElementEventListener,
	#classVars : [
		'KeyCharacterMapping'
	],
	#category : #'BlocHost-Morphic-World'
}

{ #category : #'class initialization' }
BlMorphicWorldEmbeddingEventHandler class >> initialize [
	"
	self initialize
	"
	KeyCharacterMapping := Dictionary new.
	{
	 #backspace . Character backspace.
	 #tab . Character tab.
	 #home . Character home.
	 #arrowLeft . Character arrowLeft.
	 #arrowUp . Character arrowUp.
	 #arrowRight . Character arrowRight.
	 #arrowDown . Character arrowDown.
	 #end . Character end.
	 #pageUp . Character pageUp.
	 #pageDown . Character pageDown.
	 #delete. Character delete.
	
	 #zero . $0.
	 #one . $1.
	 #two . $2.
	 #three . $3.
	 #four . $4.
	 #five . $5.
	 #six . $6.
	 #seven . $7.
	 #eight . $8.
	 #nine . $9.
	 #slash . $/.
	 #backslash . $\.
	 #minus . $-.
	 #return . Character cr.
	 #period . $..
	} pairsDo: [ :key :val | KeyCharacterMapping at: (BlKeyboardKey perform: key) put: val ]
]

{ #category : #converting }
BlMorphicWorldEmbeddingEventHandler >> convertButton: aBlMouseButton [
	aBlMouseButton = BlMouseButton primary
		ifTrue: [ ^ MouseButtonEvent redButton ].
	aBlMouseButton = BlMouseButton middle
		ifTrue: [ ^ MouseButtonEvent blueButton ].
	aBlMouseButton = BlMouseButton secondary
		ifTrue: [ ^ MouseButtonEvent yellowButton ].
		
	^ 0
]

{ #category : #converting }
BlMorphicWorldEmbeddingEventHandler >> convertModifiers: modifiers [
	| buttons |
	buttons := 0.
	
	"Alt/Option key"
	modifiers isAlt ifTrue: [
		"On windows and unix, treat alt key as command key"
		buttons := Smalltalk os isWin32 | Smalltalk os isUnix
			ifTrue: [ buttons | 2r01000000 ]
			ifFalse: [ buttons | 2r00100000 ] ].

	modifiers isCtrl ifTrue: [ buttons := buttons | 2r00010000 ]. "Control key"
	modifiers isShift ifTrue: [ buttons := buttons | 8 ]. "Shift key"
	modifiers isCmd ifTrue: [ buttons := buttons | 2r01000000 ]. "Cmd key"

	^ buttons
]

{ #category : #events }
BlMorphicWorldEmbeddingEventHandler >> dispatchMorphicEvent: anEvent hand: aHandMorph [
	aHandMorph
		ifNotNil: [
			aHandMorph handleEvent: anEvent ]
		ifNil: [ NonInteractiveTranscript stderr show: ('Can not handle {1} because hand is nil' format: { anEvent }); cr ]
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> keyDownEvent: anEvent [
	| aHand aMorphicEvent |
	
	anEvent consumed: true.
	aHand := anEvent currentTarget activeHand.

	aMorphicEvent := KeyboardEvent new
		setType: #keyDown
		buttons: (self convertModifiers: anEvent modifiers)
		position: anEvent position
		keyValue: (self mapKeyToCharacter: anEvent key) charCode
		charCode: (self mapKeyToCharacter: anEvent key) charCode
		hand:  aHand
		stamp: Time millisecondClockValue.
	aMorphicEvent scanCode: anEvent scanCode.

	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> keyUpEvent: anEvent [
	| aHand aMorphicEvent |
	
	anEvent consumed: true.
	aHand := anEvent currentTarget activeHand.

	aMorphicEvent := KeyboardEvent new
		setType: #keyUp
		buttons: (self convertModifiers: anEvent modifiers)
		position: anEvent position
		keyValue: (self mapKeyToCharacter: anEvent key) charCode
		charCode: (self mapKeyToCharacter: anEvent key) charCode
		hand:  aHand
		stamp: Time millisecondClockValue.
	aMorphicEvent scanCode: anEvent scanCode.

	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> mapKeyToCharacter: aKeyboardKey [
	
	^ KeyCharacterMapping
		at: aKeyboardKey
		ifAbsent: [ Character null ]
]

{ #category : #'mouse handlers' }
BlMorphicWorldEmbeddingEventHandler >> mouseDownEvent: anEvent [
	| aHand aMorphicEvent |

	anEvent consumed: true.
	
	aHand := anEvent currentTarget activeHand.
	
	anEvent currentTarget world beCursorOwner.

	aMorphicEvent := MouseButtonEvent new
		setType: #mouseDown 
		position: anEvent localPosition
		which: (self convertButton: anEvent button)
		buttons: (self convertModifiers: anEvent modifiers) | (self convertButton: anEvent button)
		hand: aHand
		stamp: Time millisecondClockValue.
		
	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> mouseMoveEvent: anEvent [
	| aHand aMorphicEvent oldPos |

	anEvent consumed: true.
	
	aHand := anEvent currentTarget activeHand.
	oldPos := aHand position.

	anEvent currentTarget world beCursorOwner.

	aMorphicEvent := MouseMoveEvent basicNew
		setType: #mouseMove 
		startPoint: oldPos
		endPoint: anEvent localPosition 
		trail: { oldPos. anEvent localPosition }
		buttons: (self convertModifiers: anEvent modifiers)
		hand: aHand
		stamp: Time millisecondClockValue.

	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #'mouse handlers' }
BlMorphicWorldEmbeddingEventHandler >> mouseUpEvent: anEvent [
	| aHand aMorphicEvent |

	anEvent consumed: true.

	aHand := anEvent currentTarget activeHand.
	
	anEvent currentTarget world beCursorOwner.

	aMorphicEvent := MouseButtonEvent new
		setType: #mouseUp
		position: anEvent localPosition 
		which: (self convertButton: anEvent button)
		buttons: (self convertModifiers: anEvent modifiers)
		hand: aHand
		stamp: Time millisecondClockValue.
		
	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> scrollEvent: anEvent [
	| vertical aHand aMorphicEvent |
	
	anEvent consumed: true.
	
	anEvent currentTarget world beCursorOwner.

	anEvent vector x abs > anEvent vector y abs
		ifTrue: [ ^ self ].

	vertical := anEvent vector y.
	
	aHand := anEvent currentTarget activeHand.

	aMorphicEvent := MouseWheelEvent new 
		setType: #mouseWheel
		position: anEvent localPosition
		direction: (vertical > 0 ifTrue: [ Character arrowUp ] ifFalse: [ Character arrowDown ])
		buttons: (self convertModifiers: anEvent modifiers)
		hand: aHand
		stamp: Time millisecondClockValue.
		
	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]

{ #category : #visiting }
BlMorphicWorldEmbeddingEventHandler >> textInputEvent: anEvent [
	| aHand aMorphicEvent anInputString |

	anEvent consumed: true.
	
	aHand := anEvent currentTarget activeHand.
	anInputString := anEvent text.

	aMorphicEvent := KeyboardEvent new
		setType: #keystroke
		buttons: (self convertModifiers: anEvent modifiers)
		position: aHand position
		keyValue: anInputString first charCode
		charCode: anInputString first charCode
		hand: aHand
		stamp: Time millisecondClockValue.

	self dispatchMorphicEvent: aMorphicEvent hand: aHand
]