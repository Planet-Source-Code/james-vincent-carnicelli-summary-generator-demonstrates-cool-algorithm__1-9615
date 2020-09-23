VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Summarizer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Option Compare Text

Private Const IgnoreWordsFewerThanXCharacters = 5
Private Const AcceptBelowXPercentOfWordFrequency = 0.01
Private Const AcceptAboveXPercentOfWordFrequency = 0.4

Private Const HotWords = "|about|best|essense|essential|first|important|least|most|key|summarize|summary|then|worst|"

Private Sentences As Collection
Private Words As Collection
Private WordsToIgnore As Collection
Private WordsByOccurance As Collection
Private UniqueScores As Collection

Private Source As String
Private SourceLen As Long
Private Paragraphs As Long

Public WordSequence As Collection
Public Summary As String
Public TotalRealWordsInSummary As Long
Public TotalRealWordsInSource As Long


Public Function Summarize(SourceText As String, MaximumNumberOfWords As Long) As String
    Dim MaxScoreIndex As Long, MaxScore As Double
    Dim i As Integer, Sentence As SentenceInfo
    Dim Paragraph As Long
    
    'Initialize
    TotalRealWordsInSource = 0
    Set WordSequence = New Collection
    Set Sentences = New Collection
    Set Words = New Collection
    Summary = ""
    
    'Analyze
    Source = SourceText
    SourceLen = Len(Source)
    Parse
    SortWordsByOccurance
    ScoreSentences
    
    'Assemble
    Paragraph = 0
    For MaxScoreIndex = UniqueScores.Count To 1 Step -1
        MaxScore = UniqueScores(MaxScoreIndex)
        Summary = ""
        TotalRealWordsInSummary = 0
        For i = 1 To Sentences.Count
            Set Sentence = Sentences(i)
            If Sentence.Score >= MaxScore Then
                TotalRealWordsInSummary = TotalRealWordsInSummary + Sentence.TotalRealWords
                If TotalRealWordsInSummary > MaximumNumberOfWords Then
                    Summary = ""
                    Exit For
                End If
                If Summary <> "" Then Summary = Summary & "  "
                If Paragraph <> Sentence.Paragraph Then
                    Paragraph = Sentence.Paragraph
                    If Summary <> "" Then
                        Summary = Summary & vbCrLf & vbCrLf
                    End If
                End If
                Summary = Summary & Sentence.Assemble
            End If
        Next
        If Summary <> "" Then Exit For
    Next
    
    Summarize = Summary
End Function

Private Sub Parse()
    Dim i As Long, NextWord As WordInstance, WordDef As WordInfo
    Dim Sequence As Long, SentenceSequence As Long
    Dim Sentence As SentenceInfo, StartingNewSentence As Boolean
    Dim NewParagraph As Boolean
    i = 1
    
    'Skip initial whitespace
    Do
        If i > SourceLen Then Exit Do
        If Not AreInSet(Mid(Source, i, 1), vbCrLf & vbTab & " ") Then Exit Do
        i = i + 1
    Loop
    
    Sequence = 1
    SentenceSequence = 1
    StartingNewSentence = True
    Do
        Set NextWord = ParseWord(i, WordDef, NewParagraph)
        
        If NextWord Is Nothing Then Exit Do
        
        If StartingNewSentence Then
            Set Sentence = New SentenceInfo
            Set Sentence.Parent = Me
            Sentence.Paragraph = Paragraphs
            Sentence.FirstWord = Sequence
            Sentence.SequenceIndex = SentenceSequence
            Sentences.Add Sentence
            StartingNewSentence = False
        End If
        
        If NewParagraph Then
            Paragraphs = Paragraphs + 1
        End If
        
        WordSequence.Add NextWord
        WordDef.WordSequenceOccurances.Add Sequence
        WordDef.SentenceOccurances.Add SentenceSequence
        If WordDef.IsRealWord Then
            Sentence.TotalRealWords = Sentence.TotalRealWords + 1
            TotalRealWordsInSource = TotalRealWordsInSource + 1
        End If
        
        If NextWord.IsSentenceEnd Then
            Set Sentence = Sentences(Sentences.Count)
            Sentence.LastWord = Sequence
            StartingNewSentence = True
            SentenceSequence = SentenceSequence + 1
        End If
        
        Sequence = Sequence + 1
    Loop
End Sub

Private Function ParseWord(Pos As Long, WordDef As WordInfo, NewParagraph As Boolean) As WordInstance
    Dim Word As WordInstance, Char As String
    Dim Newlines As Long
    
    If Pos > SourceLen Then Exit Function  'No more words
    
    NewParagraph = False
    
    Set Word = New WordInstance
    Char = Mid(Source, Pos, 1)
    If AreLetters(Char) Then  'A real word
        
        Do
            If Pos > SourceLen Then Exit Do
            Char = Mid(Source, Pos, 1)
            If Not AreLetters(Char) Then Exit Do
            Word.Token = Word.Token & Char
            Pos = Pos + 1
        Loop
        
        If ItemExists(Words, LCase(Word.Token)) Then
            Set WordDef = Words(LCase(Word.Token))
        Else
            Set WordDef = New WordInfo
            WordDef.IsRealWord = True
            WordDef.Token = LCase(Word.Token)
            If Len(Word.Token) < IgnoreWordsFewerThanXCharacters _
              Or ItemExists(WordsToIgnore, Word.Token) Then
                WordDef.ShouldIgnore = True
            End If
            Words.Add WordDef, WordDef.Token
        End If
        Set Word.Def = WordDef
    
    Else  'Not a real word
        
        If AreInSet(Char, ".?!") Then
            Word.IsSentenceEnd = True
            Word.Token = Char
            Pos = Pos + 1
        ElseIf AreDigits(Char) Then
            Do
                If Pos > SourceLen Then Exit Do
                Char = Mid(Source, Pos, 1)
                If Not AreDigits(Char) Then Exit Do
                Word.Token = Word.Token & Char
                Pos = Pos + 1
            Loop
        Else
            Word.Token = Char
            Pos = Pos + 1
        End If
        
    End If
    
    Do
        If Pos > SourceLen Then Exit Do
        Char = Mid(Source, Pos, 1)
        If Not AreInSet(Char, vbCrLf & vbTab & " ") Then Exit Do
        Word.FollowedByWhitespace = True
        If Char = vbLf Then
            Newlines = Newlines + 1
        End If
        Pos = Pos + 1
    Loop
    
    If Newlines >= 2 Then
        NewParagraph = True
        Word.IsSentenceEnd = True
    End If
    
    Set ParseWord = Word
End Function

Private Sub SortWordsByOccurance()
    Dim i As Long, j As Long, Def1 As WordInfo, Def2 As WordInfo
    Dim Sentence As SentenceInfo, Word As WordInstance
    
    Set WordsByOccurance = New Collection
    For i = 1 To Words.Count
        Set Def1 = Words(i)
        If Not Def1.ShouldIgnore Then
            Do
                For j = 1 To WordsByOccurance.Count
                    Set Def2 = WordsByOccurance(j)
                    If Def2.WordSequenceOccurances.Count < Def1.WordSequenceOccurances.Count Then
                        WordsByOccurance.Add Def1, , j
                        Exit Do
                    End If
                Next
                WordsByOccurance.Add Def1
                Exit Do
            Loop
        End If
    Next
    
    For i = WordsByOccurance.Count * AcceptBelowXPercentOfWordFrequency _
      To WordsByOccurance.Count * AcceptAboveXPercentOfWordFrequency
        Set Def1 = WordsByOccurance(i)
        Def1.IsInScoreRange = True
    Next
    
    For i = 1 To Sentences.Count
        Set Sentence = Sentences(i)
        For j = Sentence.FirstWord To Sentence.LastWord
            Set Word = WordSequence(j)
            If Not Word.Def Is Nothing Then
                If Word.Def.IsInScoreRange Then
                    Sentence.TotalScoringWords = Sentence.TotalScoringWords + 1
                End If
            End If
        Next
    Next
End Sub

Private Sub ScoreSentences()
    Dim i As Long, j As Long, Sentence As SentenceInfo
    Dim Word As WordInstance
    Dim Score As String, Score2 As String
    Set UniqueScores = New Collection
    For i = 1 To Sentences.Count
        Score = 0
        Set Sentence = Sentences(i)
        For j = Sentence.FirstWord To Sentence.LastWord
            Set Word = WordSequence(j)
            If Not Word.Def Is Nothing Then
                If Not Word.Def.ShouldIgnore Then
                    Score = Score + Word.Def.WordSequenceOccurances.Count
                    If InStr(1, HotWords, "|" & Word.Def.Token & "|") <> 0 Then
                        Score = Score + (WordSequence.Count * 0.05)
                    End If
                End If
            End If
        Next
        If Sentence.TotalScoringWords > 0 Then
            Score = Score / (Sentence.TotalScoringWords * 1)
            
            'Bias in favor of the first and last paragraphs
            If Sentence.Paragraph = 1 Then
                Score = Score * 4
            ElseIf Sentence.Paragraph = 2 Then
                Score = Score * 3
            ElseIf Sentence.Paragraph = 3 Then
                Score = Score * 2
            ElseIf Sentence.Paragraph = Paragraphs - 2 Then
                Score = Score * 2
            ElseIf Sentence.Paragraph = Paragraphs - 1 Then
                Score = Score * 3
            ElseIf Sentence.Paragraph = Paragraphs Then
                Score = Score * 4
            End If
            
            Score = Format(Score, "0.00")
        Else
            Score = "0.00"
        End If
        Sentence.Score = Score
        
        Do
            For j = 1 To UniqueScores.Count
                Score2 = UniqueScores(j)
                If Score2 = Score Then
                    Exit Do
                ElseIf Score2 < Score Then
                    UniqueScores.Add Score, , j
                    Exit Do
                End If
            Next
                UniqueScores.Add Score
            Exit Do
        Loop
    
    Next
End Sub

Public Function ItemExists(Col As Collection, Key As String) As Boolean
    On Error Resume Next
    Call Col.Item(Key)
    ItemExists = (Err.Number = 0)
End Function

Private Sub AddWordsToIgnore(WordList As String)
    Dim List, i As Integer
    List = Split(WordList, " ")
    For i = 0 To UBound(List)
        WordsToIgnore.Add List(i), List(i)
    Next
End Sub

Private Sub Class_Initialize()
    Set WordsToIgnore = New Collection
    AddWordsToIgnore "a an and but for in it nor not of on or out"
    AddWordsToIgnore "that the to too you your"
End Sub
