VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "SentenceInfo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Parent As Summarizer

Public Paragraph As Long
Public FirstWord As Long
Public LastWord As Long
Public TotalRealWords As Long
Public SequenceIndex As Long
Public Score As Double
Public TotalScoringWords As Long

Public Function Assemble() As String
    Dim i As Long, Word As WordInstance, WordDef As WordInfo
    For i = FirstWord To LastWord
        Set Word = Parent.WordSequence(i)
        Set WordDef = Word.Def
        Assemble = Assemble & Word.Token
        If i < LastWord And Word.FollowedByWhitespace Then
            Assemble = Assemble & " "
        End If
    Next
End Function
