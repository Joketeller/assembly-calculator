.386
.model flat,stdcall
option casemap:none

WinMain     proto :DWORD, :DWORD, :DWORD, :DWORD       ; Main window process
MessageBoxA proto :DWORD, :DWORD, :DWORD, :DWORD       ; MessageBox
MessageBox 	equ   <MessageBoxA>                        ; Show error messages

AppendText       proto StringAddr:DWORD, Text:DWORD    ; Append text at the end of string
SetEndChar       proto StringAddr:DWORD, Text:DWORD    ; Set char at the end of a string
GetEndChar       proto StringAddr:DWORD                ; Get char at the end of a string (Saves in EAX)
GetNextOperator  proto ExpAddr:DWORD                   ; Find next opertor
isOperator       proto chr:DWORD                       ; Test if char is operator
compareOperators proto StkAddr:DWORD, opt:DWORD        ; Compare priority between operators
StrToInt         proto ExpAddr:DWORD                   ; String to int
IntToStr         proto num:DWORD, StringAddr:DWORD     ; Int to string
CalProc          proto ExpAddr:DWORD                   ; Calculator main process
Calculate        proto op1:DWORD, op2:DWORD, opt:DWORD ; Actual calculation
PromptError      proto                                 ; Error prompt

include     \masm32\include\windows.inc
include     \masm32\include\user32.inc
includelib  \masm32\include\user32.lib
include     \masm32\include\kernel32.inc
includelib  \masm32\include\kernel32.lib

.data
ClassName        BYTE "CalculatorClass", 0
AppName          BYTE "Calculator", 0
ButtonClassName  BYTE "button", 0
ErrorWindowTitle BYTE "Error", 0
ErrorWindowMsg   BYTE "An error occured.", 0

ButtonText1      BYTE "1", 0
ButtonText2      BYTE "2", 0
ButtonText3      BYTE "3", 0
ButtonText4      BYTE "4", 0
ButtonText5      BYTE "5", 0
ButtonText6      BYTE "6", 0
ButtonText7      BYTE "7", 0
ButtonText8      BYTE "8", 0
ButtonText9      BYTE "9", 0
ButtonText0      BYTE "0", 0
ButtonTextAdd    BYTE "+", 0
ButtonTextSub    BYTE "-", 0
ButtonTextMul    BYTE "*", 0
ButtonTextDiv    BYTE "/", 0
ButtonTextEqu    BYTE "=", 0
ButtonTextClr    BYTE "AC", 0

EditClassName    BYTE "edit",0
TestString       BYTE "Wow! I'm in an edit box now",0

.data?
hInstance        HINSTANCE ?

ButtonOne        HWND ?
ButtonTwo        HWND ?
ButtonThree      HWND ?
ButtonFour       HWND ?
ButtonFive       HWND ?
ButtonSix        HWND ?
ButtonSeven      HWND ?
ButtonEight      HWND ?
ButtonNine       HWND ?
ButtonZero       HWND ?
ButtonAdd        HWND ?
ButtonSub        HWND ?
ButtonMul        HWND ?
ButtonDiv        HWND ?
ButtonEqu        HWND ?
ButtonClr        HWND ?
hwndEdit         HWND ?

buffer           BYTE 512 dup(?) ; Input content buffer
numberStack      BYTE 512 dup(?) ; Number stack
operatorStack    BYTE 512 dup(?) ; Operator stack
result           BYTE 512 dup(?) ; Result stack

.const
EditID           equ 10

ButtonAddID      equ 11
ButtonSubID      equ 12
ButtonMulID      equ 13
ButtonDivID      equ 14
ButtonEquID      equ 15
ButtonClrID      equ 16

IDM_CLEAR        equ 1
IDM_EXIT         equ 2
IDM_UPDATETEXT   equ 3
IDM_APPENDTEXT   equ 4

.code
main:
  invoke GetModuleHandle, NULL
  mov hInstance, eax
  invoke WinMain, hInstance, NULL, NULL, SW_SHOWDEFAULT
  invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
  local wc:WNDCLASSEX
  local msg:MSG
  local hwnd:HWND
  mov wc.cbSize,SIZEOF WNDCLASSEX
  mov wc.style, CS_HREDRAW or CS_VREDRAW
  mov wc.lpfnWndProc, OFFSET WndProc
  mov wc.cbClsExtra, NULL
  mov wc.cbWndExtra, NULL
  push hInst
  pop wc.hInstance
  mov wc.hbrBackground, COLOR_BTNFACE+1
  mov wc.lpszClassName, OFFSET ClassName
  invoke LoadIcon, NULL, IDI_APPLICATION
  mov wc.hIcon, eax
  mov wc.hIconSm, eax
  invoke LoadCursor, NULL, IDC_ARROW
  mov wc.hCursor, eax
  invoke RegisterClassEx, ADDR wc

  ; Create main window
  invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassName, ADDR AppName, \
    WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, \
    CW_USEDEFAULT, 250, 320, NULL, NULL, \
    hInstance, NULL
  mov hwnd, eax
  invoke ShowWindow, hwnd, SW_SHOWNORMAL
  invoke UpdateWindow, hwnd

  ; Message loop
  .WHILE TRUE
    invoke GetMessage, ADDR msg, NULL, 0, 0
    .BREAK .IF (!eax)
    invoke TranslateMessage, ADDR msg
    invoke DispatchMessage, ADDR msg
  .ENDW

  mov eax, msg.wParam
  ret
WinMain endp

AppendText proc StringAddr:DWORD, Text:DWORD
  push eax
  push ebx
  push ecx
  push edx
  mov eax, StringAddr
  mov ebx, Text
  xor ecx, ecx
  mov dl, [eax]
  .WHILE dl != 0
    add eax, 1
    mov dl, [eax]
  .ENDW
  mov [eax], bl
  add eax, 1
  mov [eax], cl
  pop edx
  pop ecx
  pop ebx
  pop eax
  ret
AppendText endp

; Get char at the end of the string
GetEndChar proc StringAddr:DWORD
  push ecx
  push edx
  mov eax, StringAddr
  mov dl, [eax]

  .WHILE dl != 0
    add eax, 1
    mov dl, [eax]
  .ENDW

  mov ecx, eax
  sub ecx, 1
  mov dl, [ecx]
  xor eax, eax
  mov al, dl
  pop edx
  pop ecx
  ; Store return value in EAX
  ret
GetEndChar endp

; Set char at the end of the string
SetEndChar proc StringAddr:DWORD, Text:DWORD
  push ebx
  push edx
  mov eax, StringAddr
  mov ebx, Text
  mov dl, [eax]

  .WHILE dl != 0
    add eax, 1
    mov dl, [eax]
  .ENDW

  sub eax, 1
  mov [eax], bl
  pop edx
  pop ebx
  ret
SetEndChar endp

; Check if char is operator
isOperator proc chr:DWORD
  .IF chr == '+' || chr == '-' || chr == '*' || chr == '/'
    mov eax, 1
  .ELSE
    mov eax, 0
  .ENDIF
  ret
isOperator endp

StrToInt proc ExpAddr:DWORD
  push ebx
  push ecx
  push edx
  xor ecx, ecx
  xor edx, edx
  mov ebx, ExpAddr

  invoke GetNextOperator, ebx
  mov ecx, eax
  xor eax, eax

  ; Check if number is negative or positive
  mov al, [ebx]
  invoke isOperator, al
  .IF eax == 1
    mov al, [ebx]
    .IF al == '-'
      push eax ; Number is negative
    .ELSE
      invoke PromptError
    .ENDIF
    add ebx, 1
  .ELSE
    mov al, '+'
    push eax ; Number is positive
  .ENDIF

  xor eax, eax
  .WHILE ebx < ecx
    mov dl, [ebx]
    sub dl, '0'
    ; EAX × 10
    push ebx
    mov ebx, eax
    sal eax, 3
    sal ebx, 1
    add eax, ebx
    pop ebx

    add eax, edx
    add ebx, 1
  .ENDW

  pop ebx ; Get operator at top of stack
  .IF bl == '-'
    mov ecx, 0ffffffffh
    xor eax, ecx
    add eax, 1
  .ELSEIF bl == '+'
    ; Do nothing...
  .ELSE
    invoke PromptError
  .ENDIF

  pop edx
  pop ecx
  pop ebx
  ; Store return value in EAX
  ret
StrToInt endp

IntToStr proc num:DWORD, StringAddr:DWORD
  push ebx
  push ecx
  push edx
  xor edx, edx
  xor ecx, ecx
  mov eax, num

  ; Check number's sign
  sar eax, 31
  .IF eax == 0
    ; Number is positive or zero
    ; Calculate digits
    mov eax, num
    mov ebx, 10
    ; Number is 0
    .IF eax == 0
      mov ecx, 1
    .ENDIF
    .WHILE eax != 0
      cdq
      idiv ebx
      add ecx, 1
    .ENDW
    xor edx, edx

    mov eax, num
    mov ebx, StringAddr
    ; Append '0' at the end of the string
    add ebx, ecx
    mov edx, 0
    mov [ebx], dl
    sub ebx, 1

    .WHILE ecx > 0
      push ebx
      mov ebx, 10
      cdq
      idiv ebx
      add edx, '0'
      pop ebx
      mov [ebx], dl
      sub ebx, 1
      sub ecx, 1
    .ENDW
  .ELSE
    ; Number is negative
    mov ebx, eax
    mov eax, num
    sub eax, 1
    xor eax,ebx
    push eax
    mov ebx,10

    .WHILE eax != 0
        xor edx, edx
      idiv ebx
      add ecx, 1
    .ENDW
    xor edx, edx
    add ecx, 1

    pop eax
    mov ebx, StringAddr
    ; Append '0'
    add ebx, ecx
    mov edx, 0
    mov [ebx], dl
    sub ebx, 1

    .WHILE ecx > 1
      push ebx
      mov ebx, 10
      xor edx, edx
      idiv ebx
      add edx, '0'
      pop ebx
      mov [ebx], dl
      sub ebx, 1
      sub ecx, 1
    .ENDW

    ; Add '-' at the start
    mov dl, '-'
    mov [ebx], dl
    sub ebx, 1
    sub ecx, 1

  .ENDIF
  pop edx
  pop ecx
  pop ebx
  ret
IntToStr endp

GetNextOperator proc ExpAddr:DWORD
  push ebx
  push ecx
  xor eax, eax
  xor ecx, ecx
  mov ebx, ExpAddr
  mov cl, [ebx]

  .IF cl == 0
    mov eax,1
  .ENDIF
  ; Find next symbol
  .WHILE eax != 1
    add ebx, 1
    mov cl, [ebx]
    invoke isOperator, ecx
    .IF cl == 0
      mov eax, 1
    .ENDIF
  .ENDW
  mov eax, ebx
  pop ecx
  pop ebx
  ret
GetNextOperator endp

compareOperators proc StkAddr:DWORD, opt:DWORD
  push ebx
  push ecx
  mov ebx,StkAddr
  mov ecx,[ebx]

  .IF opt == '*' || opt == '/'
    .IF  ecx == '*' || ecx == '/'
      xor eax,eax
    .ELSE
      ; Higher priority
      mov eax, 1
    .ENDIF
  .ELSE
    .IF ecx == '*' || ecx == '/'
      xor eax, eax
    .ELSE
      xor eax, eax
    .ENDIF
  .ENDIF

  pop ecx
  pop ebx
  ret
compareOperators endp

PromptError proc
  push eax
  push ebx
  push ecx
  push edx
  invoke MessageBox, NULL, ADDR ErrorWindowMsg, ADDR ErrorWindowTitle, MB_OK
  pop edx
  pop ecx
  pop ebx
  pop eax
  ret
PromptError	endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
  .IF uMsg == WM_DESTROY
    invoke PostQuitMessage, NULL
  ; Initialize window creation
  .ELSEIF uMsg == WM_CREATE
    ; Add text input
    invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, \
      WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or \
      ES_AUTOHSCROLL, \
      30, 30, 165, 30, hWnd, EditID, hInstance, NULL
    mov hwndEdit, eax
    invoke SetFocus, hwndEdit
    ; Buttons
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText1, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      30, 210, 30, 30, hWnd, 1, hInstance, NULL
    mov ButtonOne, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText2, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      75, 210, 30, 30, hWnd, 2, hInstance, NULL
    mov ButtonTwo, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText3, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      120, 210, 30, 30, hWnd, 3, hInstance, NULL
    mov ButtonThree, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText4, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      30, 165, 30, 30, hWnd, 4, hInstance, NULL
    mov ButtonFour, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText5, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      75, 165, 30, 30, hWnd, 5, hInstance, NULL
    mov ButtonFive, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText6, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      120, 165, 30, 30, hWnd, 6, hInstance, NULL
    mov ButtonSix, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText7, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      30, 120, 30, 30, hWnd, 7, hInstance, NULL
    mov ButtonSeven, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText8, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      75, 120, 30, 30, hWnd, 8, hInstance, NULL
    mov ButtonEight, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText9, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      120, 120, 30, 30, hWnd, 9, hInstance, NULL
    mov ButtonNine, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText0, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      75, 75, 30, 30, hWnd, 0, hInstance, NULL
    mov ButtonZero,eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextAdd, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      165, 165, 30, 30, hWnd, ButtonAddID, hInstance, NULL
    mov ButtonAdd, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextSub, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      165, 120, 30, 30, hWnd, ButtonSubID, hInstance, NULL
    mov ButtonSub,eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextMul, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      165, 75, 30, 30, hWnd, ButtonMulID, hInstance, NULL
    mov ButtonMul, eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextDiv, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\
      120, 75, 30, 30, hWnd, ButtonDivID, hInstance, NULL
    mov ButtonDiv,eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextEqu, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      165, 210, 30, 30, hWnd, ButtonEquID, hInstance, NULL
    mov ButtonEqu,eax
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonTextClr, \
      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
      30, 75, 30, 30, hWnd, ButtonClrID, hInstance, NULL
    mov ButtonClr, eax

  .ELSEIF uMsg == WM_COMMAND
    mov eax, wParam
    .IF lParam == 0
      ; 指令处理区域
      .IF ax == IDM_CLEAR
        invoke SetWindowText,hwndEdit,NULL
      .ELSEIF ax == IDM_UPDATETEXT
        invoke GetWindowText, hwndEdit, ADDR buffer, 512
        invoke CalProc, ADDR buffer
        invoke IntToStr, eax, ADDR result
        invoke SetWindowText, hwndEdit, ADDR result
      .ELSE
        invoke DestroyWindow, hWnd
      .ENDIF
    ; 数字处理
    .ELSEIF lParam >= '0' && lParam <= '9'
      ; 输入处理
        invoke GetWindowText, hwndEdit, ADDR buffer, 512
        invoke AppendText, ADDR buffer, lParam
        invoke SetWindowText, hwndEdit, ADDR buffer
    ; 符号处理
    .ELSEIF lParam == '+' || lParam == '-' || lParam == '*' || lParam == '/'
      ; 如果前面有符号:
      invoke GetWindowText, hwndEdit, ADDR buffer, 512
      invoke GetEndChar, ADDR buffer
      invoke isOperator, eax
      .IF eax == 1
        invoke SetEndChar, ADDR buffer, 0
      .ENDIF
      invoke AppendText, ADDR buffer, lParam
      invoke SetWindowText, hwndEdit, ADDR buffer
    .ELSE
      ; 按钮函数回调区域
      .IF ax == 1
        shr eax,16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '1'
        .ENDIF
      .ELSEIF ax == 2
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '2'
        .ENDIF
      .ELSEIF ax == 3
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '3'
        .ENDIF
      .ELSEIF ax == 4
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '4'
        .ENDIF
      .ELSEIF ax == 5
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '5'
        .ENDIF
      .ELSEIF ax == 6
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '6'
        .ENDIF
      .ELSEIF ax == 7
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '7'
        .ENDIF
      .ELSEIF ax == 8
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '8'
        .ENDIF
      .ELSEIF ax == 9
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '9'
        .ENDIF
      .ELSEIF ax == 0
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '0'
        .ENDIF
      .ELSEIF ax == ButtonAddID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '+'
        .ENDIF
      .ELSEIF ax == ButtonSubID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '-'
        .ENDIF
      .ELSEIF ax == ButtonMulID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '*'
        .ENDIF
      .ELSEIF ax == ButtonDivID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_APPENDTEXT, '/'
        .ENDIF
      .ELSEIF ax == ButtonEquID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_UPDATETEXT, 0
        .ENDIF
      .ELSEIF ax == ButtonClrID
        shr eax, 16
        .IF ax == BN_CLICKED
          invoke SendMessage, hWnd, WM_COMMAND, IDM_CLEAR, 0
        .ENDIF
      .ENDIF
    .ENDIF
  .ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
  .ENDIF
  xor eax, eax
  ret
WndProc endp

Calculate proc op1:DWORD, op2:DWORD, opt:DWORD
  push ebx
  push ecx
  push edx
  xor eax, eax
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx

  .IF opt == '+'
    mov eax, op1
      add eax, op2
  .ELSEIF opt == '-'
    mov eax, op1
      sub eax, op2
  .ELSEIF opt == '*'
    mov eax, op1
    imul op2
  .ELSEIF opt == '/'
    mov eax, op1
    mov ebx, op2
    cdq
    .IF ebx == 0
      invoke PromptError
      mov ebx, 1
    .ENDIF
    idiv ebx
  .ELSE
    invoke PromptError
  .ENDIF
  pop edx
  pop ecx
  pop ebx
  ret
Calculate endp

; Calculate process
CalProc proc ExpAddr:DWORD
  push ebx ; Number stack
  push ecx ; Operator stack
  push edx ; Expression progress
  mov ebx, OFFSET numberStack
  mov ecx, OFFSET operatorStack
  mov edx, ExpAddr

  .WHILE edx != 0
    invoke StrToInt, edx
    ; Push into numbers stack
    mov [ebx], eax
    add ebx, 4

    invoke GetNextOperator, edx
    mov edx, eax
    xor eax, eax
    mov al, [edx]
    invoke isOperator, eax
    .IF eax == 1
      mov al, [edx]

      ; Compare with operator at the top of the stack
      invoke compareOperators, ecx, eax
      .IF eax == 0
        .WHILE ecx > OFFSET operatorStack && eax == 0
          sub ecx, 4
          push ecx
          push edx

          mov eax, [ecx]

          sub ebx, 4
          mov ecx, [ebx]
          sub ebx, 4
          mov edx, [ebx]

          invoke Calculate, edx, ecx, eax
          mov [ebx], eax
          add ebx, 4

          pop edx
          pop ecx
          .IF ecx > OFFSET operatorStack
            invoke compareOperators, ecx, eax
          .ENDIF
        .ENDW
      .ENDIF
        xor eax, eax
        mov al, [edx]
        mov [ecx], eax
        add ecx, 4
        add edx, 1

    .ELSE
      mov eax, [ebx]
      xor edx, edx
    .ENDIF
  .ENDW

  .WHILE ecx > OFFSET operatorStack
    sub ecx, 4
    push ecx
    push edx

    mov eax, [ecx]
    sub ebx, 4
    mov ecx, [ebx]
    sub ebx, 4
    mov edx, [ebx]
    invoke Calculate, edx, ecx, eax
    mov [ebx], eax
    add ebx, 4
    pop edx
    pop ecx
  .ENDW

  ; Final result
  sub ebx, 4
  mov eax, [ebx]
  pop edx
  pop ecx
  pop ebx
  ret
CalProc endp

end main