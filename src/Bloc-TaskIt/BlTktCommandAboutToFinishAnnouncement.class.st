Class {
	#name : #BlTktCommandAboutToFinishAnnouncement,
	#superclass : #BlTktCommandAnnouncement,
	#instVars : [
		'result'
	],
	#category : #'Bloc-TaskIt-Announcements'
}

{ #category : #accessing }
BlTktCommandAboutToFinishAnnouncement >> result [
	"Return a command execution result"
	<return: #Object>
	^ result
]

{ #category : #accessing }
BlTktCommandAboutToFinishAnnouncement >> result: anObject [
	result := anObject
]