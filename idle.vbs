Dim objResult

Set objShell = WScript.CreateObject("WScript.Shell")    


Do While True
  objResult = objShell.sendkeys("{NUMLOCK}{NUMLOCK}")
  Wscript.Sleep (720000)
Loop

WScript.Echo "Hello"
