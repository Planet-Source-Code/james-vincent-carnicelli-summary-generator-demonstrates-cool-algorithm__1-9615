VERSION 5.00
Begin VB.Form Demo 
   Caption         =   "Text Summarizer Demo"
   ClientHeight    =   6855
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9690
   LinkTopic       =   "Form1"
   ScaleHeight     =   6855
   ScaleWidth      =   9690
   StartUpPosition =   3  'Windows Default
   Begin VB.TextBox MaxWords 
      Height          =   285
      Left            =   4230
      TabIndex        =   5
      Text            =   "50"
      Top             =   6480
      Width           =   555
   End
   Begin VB.CommandButton Summarize 
      Caption         =   "Summarize"
      Default         =   -1  'True
      Height          =   330
      Left            =   2385
      TabIndex        =   4
      Top             =   6480
      Width           =   1500
   End
   Begin VB.TextBox Destination 
      Height          =   3255
      Left            =   45
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   2
      Top             =   3150
      Width           =   9600
   End
   Begin VB.TextBox Source 
      Height          =   2535
      Left            =   45
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   0
      Text            =   "Demo.frx":0000
      Top             =   270
      Width           =   9600
   End
   Begin VB.Label Label 
      Caption         =   "words or fewer"
      Height          =   240
      Index           =   3
      Left            =   4860
      TabIndex        =   7
      Top             =   6525
      Width           =   1095
   End
   Begin VB.Label Label 
      Caption         =   "in"
      Height          =   240
      Index           =   2
      Left            =   3960
      TabIndex        =   6
      Top             =   6525
      Width           =   195
   End
   Begin VB.Label Label 
      Caption         =   "Destination Summary:"
      Height          =   240
      Index           =   1
      Left            =   90
      TabIndex        =   3
      Top             =   2880
      Width           =   1590
   End
   Begin VB.Label Label 
      Caption         =   "Source Text:"
      Height          =   240
      Index           =   0
      Left            =   90
      TabIndex        =   1
      Top             =   45
      Width           =   1590
   End
End
Attribute VB_Name = "Demo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private SummaryEngine As Summarizer

Private Sub Form_Load()
    Set SummaryEngine = New Summarizer
End Sub

Private Sub Summarize_Click()
    Dim Output As String
    MousePointer = vbHourglass
    SummaryEngine.Summarize Source.Text, MaxWords.Text
    Destination.Text = "Started with " & SummaryEngine.TotalRealWordsInSource & " words" & vbCrLf & _
      "Condensed to " & SummaryEngine.TotalRealWordsInSummary & " words" & vbCrLf & vbCrLf & _
      SummaryEngine.Summary
    MousePointer = vbArrow
End Sub
