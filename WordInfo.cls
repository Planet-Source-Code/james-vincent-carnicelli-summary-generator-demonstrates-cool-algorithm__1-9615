VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "WordInfo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Token As String
Public ShouldIgnore As Boolean
Public WordSequenceOccurances As Collection
Public SentenceOccurances As Collection
Public IsRealWord As Boolean
Public IsInScoreRange As Boolean

Private Sub Class_Initialize()
    Set WordSequenceOccurances = New Collection
    Set SentenceOccurances = New Collection
End Sub


