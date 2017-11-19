.386
.model flat, stdcall
option casemap:none

include  windows.inc
include  gdi32.inc
includelib  gdi32.lib
include  user32.inc
includelib  user32.lib
include  kernel32.inc
includelib  kernel32.lib
include  Irvine32.inc
includelib  Irvine32.lib
include  msvcrt.inc
includelib  msvcrt.lib
include  Msimg32.inc
includelib  Msimg32.lib

Hero  struct
  hBmp  HBITMAP  ?
  pos  POINT  <>
  h_size _SIZE  <>
  curFrameIndex  DWORD  ?
  maxFrameSize  DWORD  ?
  speed_x  SDWORD  ?
  speed_y  SDWORD  ?
  g  DWORD  ?
  jumping  DWORD  ?
Hero  ends

Brick  struct
  hBmp  HBITMAP  ?
  pos  POINT  <>
  b_size _SIZE  <>
  color  DWORD  ? ;蓝 紫 绿 黄 石
  clicked  DWORD  ?
  painted  DWORD  ?
  speed_x  SDWORD  ?
  speed_y  SDWORD  ?
  g  DWORD  ?
Brick  ends

.data?
hInstance  dd  ?
hWinMain  dd  ?
m_BackgroundBmp  HBITMAP  ?
m_GameWinBmp  HBITMAP  ?
m_HeroBmp  HBITMAP  ?
m_BrickBmp  HBITMAP  5 DUP(?)
m_LabelBmp  HBITMAP  5 DUP(?)
m_EnergyBmp  HBITMAP  ?
m_InstructionBmp  HBITMAP  ?
m_GameOverBmp  HBITMAP  ?

.data
IDB_START  equ  100
IDB_BACKGROUND  equ  101
IDB_HERO  equ  107
IDB_STONE_BRICK  equ 105
IDB_YELLOW_BRICK  equ  106
IDB_BLUE_BRICK  equ  102
IDB_PURPLE_BRICK  equ  104
IDB_GREEN_BRICK  equ  103
IDB_LABEL  equ  108
IDB_LABEL_TWO  equ  110
IDB_LABEL_THREE  equ  111
IDB_LABEL_FOUR  equ  112
IDB_LABEL_FIVE  equ  113
IDB_ENERGY  equ  109
IDB_INSTRUCTION  equ  114
IDB_GAMEOVER  equ  115
IDB_GAMEWIN  equ  116
ICO_MAIN  equ  200

TIMER_ID  equ  1
TIMER_ELAPSE  equ  25
HERO_SIZE_X  equ  75
HERO_SIZE_Y  equ  74
HERO_MAX_FRAME_NUM  equ  4
BRICK_SIZE_X  equ  75
BRICK_SIZE_Y  equ  75
BACKGROUND_SIZE_X  equ  500
BACKGROUND_SIZE_Y  equ  700
BLOCK_COLOR_NUM  equ  5
BLOCK_NUM_X  equ  10
BLOCK_NUM_Y  equ  20
WINDOWS_X  equ  100
WINDOWS_Y  equ  100
WINDOWS_WIDTH  equ  500
WINDOWS_HEIGHT  equ  720

SPEED_X  equ  5
SPEED_Y  equ  20
HERO_X  equ  200
MAP_ROW equ  100
MAP_COL  equ  30

szClassName  db  'Myclass', 0
szCaptionMain  db  'My first Window!', 0
szMode db 'r', 0
filename BYTE 'Best.txt', 0
;0-开始， 1-游戏，2-失败，3-说明， 4- 胜利
GameState  dd  0
TotalGrade  dd  0
MapStartX  dd  ?
MapStartY  dd  300
BrickXSpeed  SDWORD  0
BrickYSpeed  SDWORD  0
m_brickBmpNames  dd  IDB_BLUE_BRICK, IDB_PURPLE_BRICK, IDB_GREEN_BRICK, IDB_YELLOW_BRICK, IDB_STONE_BRICK
m_heartBmpNames  dd  IDB_LABEL, IDB_LABEL_TWO, IDB_LABEL_THREE, IDB_LABEL_FOUR, IDB_LABEL_FIVE
m_hero  Hero  <>

ClickedBrick  DWORD  5 DUP(-1)
CurColor  DWORD  ?
ClickedBrickNum  dd  0

EnergyNum  DWORD  15
Score  DWORD  0
Best  DWORD  0
szText1  db  13 DUP(0)
szText2  db  "%d", 0
szText3  db  "Depth:  %d", 0
szText4  db  "Best:  %d", 0

m_Map Brick 30 DUP(<>)
RowSize = $ - m_Map
  Brick 2970 DUP(<>)

.code

Rand proc uses edx edi esi, Min, Max, seed
  local @dwRet:DWORD
  local @random:DWORD
  pushad
  ;invoke crt_srand, seed
  invoke crt_rand
  mov @random, eax
  xor edx, edx
  mov ecx, 4
  div ecx
  mov @dwRet, edx
  popad
  mov eax, @dwRet
  ret
Rand endp

CreateHero proc
  pushad
  mov eax, m_HeroBmp
  mov m_hero.hBmp, eax
  mov m_hero.pos.x, HERO_X
  mov m_hero.pos.y, 226
  mov m_hero.h_size.x, HERO_SIZE_X
  mov m_hero.h_size.y, HERO_SIZE_Y
  mov m_hero.curFrameIndex, 0
  mov m_hero.maxFrameSize, HERO_MAX_FRAME_NUM
  mov m_hero.speed_x, 0
  mov m_hero.speed_y, 0
  mov m_hero.jumping, 0
  mov m_hero.g, 1
  popad
  ret
CreateHero endp

CreateSingleBrick proc uses ebx edx edi esi, Brick_order, Brick_row, Brick_column
  local @random_order:DWORD
  pushad
  mov eax, Brick_order
  mov m_Map[eax].b_size.x, BRICK_SIZE_X
  mov m_Map[eax].b_size.y, BRICK_SIZE_Y
  mov m_Map[eax].clicked, 0
  mov m_Map[eax].painted, 1
  mov m_Map[eax].speed_x, 0
  mov m_Map[eax].speed_y, 0
  mov m_Map[eax].g, 1

  ; 关于图片参数的初始化
  mov ebx, BLOCK_COLOR_NUM
  sub ebx, 1
  invoke Rand, 0, ebx, Brick_order
  mov @random_order, eax
  ; 自主规定某些方块为障碍物~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  .if Brick_row == 1
    .if Brick_column == 2 || Brick_column == 10 ||Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 2
    .if Brick_column == 4 || Brick_column == 15 ||Brick_column == 18
      mov @random_order, 4
    .endif
  .elseif Brick_row == 3
    .if Brick_column ==  10|| Brick_column == 13 ||Brick_column == 19
      mov @random_order, 4
    .endif
  .elseif Brick_row == 4
    .if Brick_column == 0 || Brick_column == 17 ||Brick_column == 29
      mov @random_order, 4
    .endif
  .elseif Brick_row == 8
    .if Brick_column == 0 || Brick_column == 1 ||Brick_column == 2 ||Brick_column == 3 ||Brick_column == 4
      mov @random_order, 4
    .endif
  .elseif Brick_row == 15
    .if Brick_column == 19 || Brick_column == 26 ||Brick_column == 29
      mov @random_order, 4
    .endif
  .elseif Brick_row == 17
    .if Brick_column == 2 || Brick_column == 10 ||Brick_column == 15
      mov @random_order, 4
    .endif
  .elseif Brick_row == 20
    .if Brick_column == 25 ||Brick_column == 26 ||Brick_column == 27 || Brick_column == 28 ||Brick_column == 29
      mov @random_order, 4
    .endif
  .elseif Brick_row == 25
    .if Brick_column == 2 || Brick_column == 5
      mov @random_order, 4
    .endif
  .elseif Brick_row == 26
    .if Brick_column == 0 || Brick_column == 10 ||Brick_column == 14
      mov @random_order, 4
    .endif
  .elseif Brick_row == 30
    .if Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 31
    .if Brick_column == 5 || Brick_column == 15 ||Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 32
    .if Brick_column == 3||Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 33
    .if Brick_column == 26||Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 34
      .if Brick_column == 24||Brick_column == 20
      mov @random_order, 4
     .endif
  .elseif Brick_row == 42
    .if Brick_column == 2 || Brick_column == 3 ||Brick_column == 4||Brick_column == 5||Brick_column == 6
      mov @random_order, 4
    .endif
  .elseif Brick_row == 45
    .if Brick_column == 25 ||Brick_column == 27
      mov @random_order, 4
    .endif
  .elseif Brick_row == 50
    .if Brick_column == 15
      mov @random_order, 4
    .endif
  .elseif Brick_row == 52
    .if Brick_column == 2 || Brick_column == 29
      mov @random_order, 4
    .endif
  .elseif Brick_row == 53
    .if Brick_column == 2 || Brick_column == 10
      mov @random_order, 4
    .endif
  .elseif Brick_row == 54
    .if Brick_column == 2
      mov @random_order, 4
    .endif
  .elseif Brick_row == 55
    .if Brick_column == 2
      mov @random_order, 4
    .endif
  .elseif Brick_row == 56
    .if Brick_column == 2 || Brick_column == 15 ||Brick_column == 17
      mov @random_order, 4
    .endif
  .elseif Brick_row == 57
    .if Brick_column == 2 || Brick_column == 10 ||Brick_column == 20
      mov @random_order, 4
    .endif
  .elseif Brick_row == 72
    .if Brick_column == 3 || Brick_column == 12 ||Brick_column == 28
      mov @random_order, 4
    .endif
  .elseif Brick_row == 74
    .if Brick_column == 15 || Brick_column == 16 ||Brick_column == 17 ||Brick_column == 18 ||Brick_column == 19
      mov @random_order, 4
    .endif
  .elseif Brick_row == 80
    .if Brick_column == 7 || Brick_column == 18 ||Brick_column == 26
      mov @random_order, 4
    .endif
  .elseif Brick_row == 82
    .if Brick_column == 8 || Brick_column == 15
      mov @random_order, 4
    .endif
  .elseif Brick_row == 85
    .if Brick_column == 2 || Brick_column == 13 ||Brick_column == 27
      mov @random_order, 4
    .endif
  .elseif Brick_row == 88
    .if Brick_column == 5 || Brick_column == 27 ||Brick_column == 14
      mov @random_order, 4
    .endif
  .elseif Brick_row == 97
    .if Brick_column == 5 || Brick_column == 16 ||Brick_column == 28
      mov @random_order, 4
    .endif
  .elseif Brick_row == 98
    .if Brick_column == 5 || Brick_column == 12 ||Brick_column == 25
      mov @random_order, 4
    .endif
  .elseif Brick_row == 99
    .if Brick_column == 5 || Brick_column == 16 ||Brick_column == 29
      mov @random_order, 4
    .endif
  .endif
  mov esi, @random_order
  mov eax, TYPE HBITMAP
  mul esi
  mov ebx, Brick_order
  mov edx, m_BrickBmp[eax]
  mov m_Map[ebx].hBmp, edx
  mov m_Map[ebx].color, esi

  ; 初始化位置坐标
  mov esi, BRICK_SIZE_X
  mov eax, Brick_column
  mul esi
  add eax, MapStartX
  mov ebx, Brick_order
  mov m_Map[ebx].pos.x, eax

  mov esi, BRICK_SIZE_Y
  mov eax, Brick_row
  mul esi
  add eax, MapStartY
  mov ebx, Brick_order
  mov m_Map[ebx].pos.y, eax

  popad
  ret
CreateSingleBrick endp

CreateMap proc
  local @Brick_order:DWORD
  local @Brick_row:DWORD
  local @Brick_column:DWORD

  invoke crt_time, NULL
  invoke crt_srand, eax

  pushad
  mov ecx, MAP_ROW
  xor esi, esi
    L1:
      push ecx
      mov ecx, MAP_COL
      xor ebx, ebx
      xor edx, edx
        L2:
          push edx
          mov ax, RowSize
          mul esi
          pop edx
          add eax, ebx
          mov @Brick_order, eax
          mov @Brick_row, esi
          mov @Brick_column, edx
          invoke CreateSingleBrick, @Brick_order, @Brick_row, @Brick_column
          xor eax, eax
          add ebx, TYPE Brick
          add edx, 1
        LOOP L2
        add esi, 1
       pop ecx
      LOOP L1
  popad
  ret
CreateMap endp

Init proc uses ebx edi esi, hWnd, wParam, lParam
  mov eax, MAP_COL
  mov esi, BRICK_SIZE_X
  mul esi
  sub eax, WINDOWS_WIDTH
  mov esi, 2
  div esi
  neg eax
  mov MapStartX, eax
  ;加载各种位图 创建实例对象
  invoke LoadBitmap, hInstance, IDB_BACKGROUND
    mov m_BackgroundBmp, eax

  invoke LoadBitmap, hInstance, IDB_GAMEWIN
    mov m_GameWinBmp, eax

    pushad
    mov ecx, BLOCK_COLOR_NUM
    xor esi, esi
    L1:
      push ecx
      invoke LoadBitmap, hInstance, m_brickBmpNames[esi]
      pop ecx
      mov m_BrickBmp[esi], eax
      add esi, TYPE DWORD
    LOOP L1
    popad

    pushad
    mov ecx, 5
    xor esi, esi
    L2:
      push ecx
      invoke LoadBitmap, hInstance, m_heartBmpNames[esi]
      pop ecx
      mov m_LabelBmp[esi], eax
      add esi, TYPE DWORD
    LOOP L2
    popad

    invoke  LoadBitmap, hInstance, IDB_HERO
    mov m_HeroBmp, eax

  invoke LoadBitmap, hInstance, IDB_ENERGY
  mov m_EnergyBmp, eax

  invoke LoadBitmap, hInstance, IDB_INSTRUCTION
  mov m_InstructionBmp, eax

  invoke LoadBitmap, hInstance, IDB_GAMEOVER
  mov m_GameOverBmp, eax

  invoke CreateHero
  invoke CreateMap

  invoke InvalidateRect, hWnd, NULL, FALSE
  ret
Init endp

StartRender proc uses ebx edi esi, hWnd
  local  @stPs:PAINTSTRUCT, @hdc, @hdcBmp, @hdcBuffer
  local  @cptBmp, @m_hStartBmp
  pushad

  invoke BeginPaint, hWnd, addr @stPs
  mov @hdc, eax
  invoke CreateCompatibleBitmap, @hdc, WINDOWS_WIDTH, WINDOWS_HEIGHT
  mov @cptBmp, eax
  invoke CreateCompatibleDC, @hdc
  mov @hdcBmp, eax
  invoke CreateCompatibleDC, @hdc
  mov @hdcBuffer, eax
  invoke LoadBitmap, hInstance, IDB_START
  mov @m_hStartBmp, eax
  invoke SelectObject, @hdcBuffer, @cptBmp

  .if GameState == 0
    invoke SelectObject, @hdcBmp, @m_hStartBmp
  .elseif GameState == 3
    invoke SelectObject, @hdcBmp, m_InstructionBmp
  .endif

  invoke BitBlt, @hdcBuffer, 0, 0, WINDOWS_WIDTH, WINDOWS_HEIGHT, @hdcBmp, 0, 0, SRCCOPY
  invoke BitBlt, @hdc, 0, 0, WINDOWS_WIDTH, WINDOWS_HEIGHT, @hdcBuffer, 0, 0, SRCCOPY

  invoke DeleteObject, @cptBmp
  invoke DeleteObject, @m_hStartBmp
  invoke DeleteDC, @hdcBuffer
  invoke DeleteDC, @hdcBmp

  invoke EndPaint, hWnd, addr @stPs
  popad
  ret
StartRender endp

Multiplication proc uses ebx edx, num1, num2
  mov eax, num1
  mov ebx, num2
  mul ebx
  ret
Multiplication endp

GetBrickOrder proc uses ebx edi esi, Brick_row, Brick_column
  mov eax, RowSize
  mov esi, Brick_row
  mul esi
  mov ecx, eax
  mov eax, TYPE Brick
  mov esi, Brick_column
  mul esi
  add ecx, eax
  ret
GetBrickOrder endp

HeartPaint proc uses ebx edx, Brick_order, hdcBmp, hdcBuffer
  local @PictureOrder:DWORD
  mov eax, Brick_order
  .if m_Map[eax].clicked == 0
    ret
  .endif

  pushad
  mov edx, 0
  mov eax, 0
  .while edx < 5
    mov ecx, Brick_order
    .if ecx == ClickedBrick[eax]
      mov @PictureOrder, eax
      .break
    .endif
    add edx, 1
    add eax, TYPE DWORD
  .endw
  popad
  pushad
  mov eax, @PictureOrder
  invoke SelectObject, hdcBmp, m_LabelBmp[eax]
  popad
  push eax
  mov ebx, m_Map[eax].pos.x
  add ebx, 22
  mov edx, m_Map[eax].pos.y
  add edx, 22
  invoke TransparentBlt, hdcBuffer, ebx, edx, 31, 31, hdcBmp, 0, 0, 31, 31, 255
  pop eax
  ret
HeartPaint endp

WriteBest proc
  ;Create a new text file
  mov edx, OFFSET filename
  call CreateOutputFile
  push eax
  invoke crt_sprintf, addr szText1, addr szText2, Best
  pop eax
  mov edx, offset szText1
  mov ecx, lengthof Best
  call WriteToFile
  call CloseFile
  ret
WriteBest endp

Render proc uses ebx edi esi, hWnd
  local @stPs:PAINTSTRUCT, @hdc, @hdcBmp, @hdcBuffer
  local @cptBmp
  local @hero_curY
  local @Pen
  local @stRect:RECT
  pushad
  invoke BeginPaint, hWnd, addr @stPs
  mov @hdc, eax
  invoke CreateCompatibleBitmap, @hdc, WINDOWS_WIDTH, WINDOWS_HEIGHT
  mov @cptBmp, eax
  invoke CreateCompatibleDC, @hdc
  mov @hdcBmp, eax
  invoke CreateCompatibleDC, @hdc
  mov @hdcBuffer, eax
  invoke SelectObject, @hdcBuffer, @cptBmp
  invoke SelectObject, @hdcBmp, m_BackgroundBmp
  invoke BitBlt, @hdcBuffer, 0, 0, WINDOWS_WIDTH, WINDOWS_HEIGHT, @hdcBmp, 0, 0, SRCCOPY

;绘制Hero到缓存
  invoke Multiplication, m_hero.h_size.y, m_hero.curFrameIndex
  mov @hero_curY, eax
  invoke SelectObject, @hdcBmp, m_hero.hBmp
  invoke TransparentBlt, @hdcBuffer, m_hero.pos.x, m_hero.pos.y, m_hero.h_size.x, m_hero.h_size.y,
                        @hdcBmp, 0, @hero_curY, m_hero.h_size.x, m_hero.h_size.y, 255

;绘制地图到缓存
  pushad
  mov ecx, MAP_ROW
  xor esi, esi
  L1:
    push ecx
    mov ecx, MAP_COL
    xor ebx, ebx
    xor edx, edx
    L2:
      push edx
      mov eax, RowSize
      mul esi
      pop edx
      add eax, ebx
      push ecx
      .if m_Map[eax].painted == 1
        push eax
        invoke  SelectObject, @hdcBmp, m_Map[eax].hBmp
        pop eax
        push eax
        invoke  BitBlt, @hdcBuffer, m_Map[eax].pos.x, m_Map[eax].pos.y, m_Map[eax].b_size.x, m_Map[eax].b_size.y, @hdcBmp, 0, 0,SRCCOPY
        pop eax
        push eax
        invoke  HeartPaint, eax, @hdcBmp, @hdcBuffer
        pop eax
      .endif
      pop ecx
      xor eax, eax
      add ebx, TYPE Brick
      add edx, 1
    LOOP L2
    add esi, 1
    pop ecx
  LOOP L1
  popad

  ;绘制能量
  invoke SelectObject, @hdcBmp, m_EnergyBmp
  invoke TransparentBlt, @hdcBuffer, 350, 10, 27, 29, @hdcBmp, 0, 0, 27, 29, 255

  ;绘制结束界面
  .if GameState == 2
    invoke SelectObject, @hdcBmp, m_GameOverBmp
    invoke BitBlt, @hdcBuffer, 0, 450, WINDOWS_WIDTH, 100, @hdcBmp, 0, 0, SRCCOPY
    invoke WriteBest
  .endif

  .if GameState == 4
    invoke SelectObject, @hdcBmp, m_GameWinBmp
    invoke BitBlt, @hdcBuffer, 0, 450, WINDOWS_WIDTH, 100, @hdcBmp, 0, 0, SRCCOPY
    invoke WriteBest
  .endif

  ;EnergyNum
  mov @stRect.left, 400
  mov @stRect.right, 500
  mov @stRect.top, 0
  mov @stRect.bottom, 50
  invoke SetTextColor, @hdcBuffer, 0
  invoke SetBkMode, @hdcBuffer, TRANSPARENT
  invoke crt_sprintf, addr szText1, addr szText2, EnergyNum
  invoke DrawText, @hdcBuffer, addr szText1, -1, addr @stRect, DT_SINGLELINE or DT_LEFT or DT_VCENTER

  ;Score
  mov @stRect.left, 250
  mov @stRect.right, 350
  mov @stRect.top, 0
  mov @stRect.bottom, 50
  invoke SetTextColor, @hdcBuffer, 0
  invoke SetBkMode, @hdcBuffer, TRANSPARENT
  invoke crt_sprintf, addr szText1, addr szText3, Score
  invoke DrawText, @hdcBuffer, addr szText1, -1, addr @stRect, DT_SINGLELINE or DT_LEFT or DT_VCENTER

  ;Best
  mov @stRect.left, 150
  mov @stRect.right, 250
  mov @stRect.top, 0
  mov @stRect.bottom, 50
  invoke SetTextColor, @hdcBuffer, 0
  invoke SetBkMode, @hdcBuffer, TRANSPARENT
  invoke crt_sprintf, addr szText1, addr szText4, Best
  invoke DrawText, @hdcBuffer, addr szText1, -1, addr @stRect, DT_SINGLELINE or DT_LEFT or DT_VCENTER

;将缓冲区的信息绘制到屏幕上
  invoke BitBlt, @hdc, 0, 0, WINDOWS_WIDTH, WINDOWS_HEIGHT, @hdcBuffer, 0, 0, SRCCOPY


;回收资源所占的内存
  invoke DeleteObject, @cptBmp
  invoke DeleteDC, @hdcBuffer
  invoke DeleteDC, @hdcBmp

;结束绘制
  invoke EndPaint, hWnd, addr @stPs
  popad
  ret
Render endp

OverRender proc uses ebx edi esi, hWnd
    ret
OverRender endp

DeleteBrick proc uses esi; 将数组中的方块painted置0
  mov esi, TYPE DWORD
  mov eax, ClickedBrickNum
  .if ClickedBrickNum == 3
    dec EnergyNum
  .elseif ClickedBrickNum == 5
    inc EnergyNum
  .endif
  L:
    dec eax
    push eax
    mul esi
    mov ecx, ClickedBrick[eax]
    .if ClickedBrickNum > 2
      mov m_Map[ecx].painted, 0
    .endif
    mov m_Map[ecx].clicked, 0
    mov ClickedBrick[eax], -1
    pop eax
    cmp eax, 0
    je L_end
    loop L
  L_end:
    mov ClickedBrickNum, eax
  ret
DeleteBrick endp

GetHeroBrick proc uses ebx
  mov eax, m_hero.pos.y
  add eax, 37
  .if SDWORD ptr m_Map[0].pos.y <= eax
    sub eax, m_Map[0].pos.y
    xor edx, edx
    mov ecx, BRICK_SIZE_Y
    div ecx
    mov ebx, eax

    mov eax, m_hero.pos.x
    add eax, 37
    sub eax, m_Map[0].pos.x
    xor edx, edx
    mov ecx, BRICK_SIZE_X
    div ecx

    mov ecx, eax
    mov eax, ebx
  .elseif
    mov eax, m_hero.pos.x
    add eax, 37
    sub eax, m_Map[0].pos.x
    xor edx, edx
    mov ecx, BRICK_SIZE_X
    div ecx

    mov ecx, eax
    mov eax, -1
  .endif
  ret
GetHeroBrick endp

DropBrick proc uses esi ebx edi
  local @CurBrick_Row:DWORD
  local @CurBrick_Col:DWORD
  local @CurBrick_X:DWORD
  local @Hero_Row:DWORD
  local @Hero_Col:DWORD
  local @Flag:DWORD
  local @Flag2:DWORD
  local @NewBrick:DWORD

  invoke GetHeroBrick
  mov @Hero_Row, eax
  mov @Hero_Col, ecx

  mov eax, ClickedBrick[0]  ; 被选中的方块
  mov esi, eax
  mov ebx, m_Map[eax].pos.y
  mov edi, m_Map[eax].pos.x
  mov @CurBrick_X, edi
  mov eax, ebx
  sub eax, m_Map[0].pos.y
  xor edx, edx
  mov ecx, BRICK_SIZE_Y
  div ecx
  mov @CurBrick_Row, eax

  mov eax, edi
  sub eax, m_Map[0].pos.x
  xor edx, edx
  mov ecx, BRICK_SIZE_X
  div ecx
  mov @CurBrick_Col, eax

  mov edi, @CurBrick_Row
  .while edi < MAP_ROW
    inc edi
    invoke GetBrickOrder, edi, @CurBrick_Col
    .if @Hero_Row == edi
      mov eax, m_hero.pos.x
      mov ebx, @CurBrick_X
      sub ebx, 75
      mov edx, @CurBrick_X
      add edx, 75
      .if eax > ebx &&  eax < edx
        mov @Flag2, 1
      .else
        mov @Flag2, 0
      .endif
    .else
      mov @Flag2, 0
    .endif

    .if m_Map[ecx].painted == 1 || @Flag2 == 1
      .if @Flag == 1
        mov ecx, @NewBrick
        mov eax, m_Map[esi].color
        mov m_Map[ecx].color, eax
        mov edx, TYPE HBITMAP
        mul edx
        mov ebx, m_BrickBmp[eax]
        mov m_Map[ecx].hBmp, ebx
        mov m_Map[ecx].painted, 1
        mov m_Map[esi].painted, 0
        dec EnergyNum
        mov @Flag, 0
        .break
      .else
        .break
      .endif
    .elseif m_Map[ecx].painted == 0 && @Flag2 == 0
      mov @Flag, 1
      mov @NewBrick, ecx
    .endif
  .endw
  mov m_Map[esi].clicked, 0
  mov ClickedBrickNum, 0
  mov eax, -1
  mov ClickedBrick[0], eax
  ret
DropBrick endp

;水平方向碰撞检测，碰到左边eax为1，右边为2，否则为0
DetectH proc uses ebx edi esi
  local @Brick_row:DWORD
  local @Brick_column:DWORD
  local @Brick_order:DWORD

  invoke GetHeroBrick
  .if eax == -1
    mov eax, 0
  .else
    mov @Brick_row, eax
    mov @Brick_column, ecx
    invoke GetBrickOrder, @Brick_row, @Brick_column
    mov @Brick_order, ecx
    mov eax, @Brick_order
    add eax, TYPE Brick  ;右边方块
    sub ecx, TYPE Brick  ;左边方块
    mov edx, m_hero.pos.x
    sub edx, m_Map[ecx].pos.x
    mov ebx, m_Map[eax].pos.x
    sub ebx, m_hero.pos.x
    .if m_Map[ecx].painted == 1 && edx < 75
      mov eax, 1
    .elseif m_Map[eax].painted == 1 && ebx < 75
      mov eax, 2
    .else
      mov eax, 0
    .endif
  .endif
  ret
DetectH endp

;竖直顶部碰撞检测，碰到以后eax为1，否则为0
DetectVTop proc
  local @Hero_Row, @Hero_Column
  local @Up_Brick_Row, @Up_Brick_Column
  local @LeftUp_Brick_Row, @LeftUp_Brick_Column
  local @RightUp_Brick_Row, @RightUp_Brick_Column
  mov eax, 0
  invoke GetHeroBrick
  mov @Hero_Row, eax
  sub eax, 1
  mov @Up_Brick_Row, eax
  mov @LeftUp_Brick_Row, eax
  mov @RightUp_Brick_Row, eax
  mov @Hero_Column, ecx
  mov @Up_Brick_Column, ecx
  sub ecx, 1
  mov @LeftUp_Brick_Column, ecx
  add ecx, 2
  mov @RightUp_Brick_Column, ecx
  .if @Hero_Row == -1 || @Hero_Row == 0
    mov eax, 0
    ret
  .endif
  invoke GetBrickOrder, @Up_Brick_Row, @Up_Brick_Column
  .if m_Map[ecx].painted == 1
    mov ebx, m_Map[ecx].pos.y
    add ebx, BRICK_SIZE_Y
    .if ebx >= m_hero.pos.y
      mov eax, 1
      ret
    .else
      mov eax, 0
      ret
    .endif
  .else
    invoke GetBrickOrder, @LeftUp_Brick_Row, @LeftUp_Brick_Column
    mov edx, m_Map[ecx].pos.x
    add edx, BRICK_SIZE_X
    sub edx, 10
  ;add edx, 10
    .if edx >= m_hero.pos.x && m_Map[ecx].painted == 1
      mov edx, m_Map[ecx].pos.y
      add edx, BRICK_SIZE_Y
      .if edx >= m_hero.pos.y
        mov eax, 1
        ret
      .endif
    .endif
    invoke GetBrickOrder, @RightUp_Brick_Row, @RightUp_Brick_Column
    mov edx, m_hero.pos.x
    add edx, HERO_SIZE_X
    sub edx, 10
   .if edx >= m_Map[ecx].pos.x && m_Map[ecx].painted == 1
      mov edx, m_Map[ecx].pos.y
      add edx, BRICK_SIZE_Y
      .if edx >= m_hero.pos.y
        mov eax, 1
        ret
      .else
        mov eax, 0
        ret
      .endif
    .endif
    mov eax, 0
    ret
  .endif
ret
DetectVTop endp

;竖直底部碰撞检测，碰到以后eax为1，否则为0
DetectVBottom proc
  local @Hero_Row, @Hero_Column
  local @Down_Brick_Row, @Down_Brick_Column
  local @LeftDown_Brick_Row, @LeftDown_Brick_Column
  local @RightDown_Brick_Row, @RightDown_Brick_Column
   mov eax, 1
  invoke GetHeroBrick
  mov @Hero_Row, eax
  add eax, 1
  mov @Down_Brick_Row, eax
  mov @LeftDown_Brick_Row, eax
  mov @RightDown_Brick_Row, eax
  mov @Hero_Column, ecx
  mov @Down_Brick_Column, ecx
  sub ecx, 1
  mov @LeftDown_Brick_Column, ecx
  add ecx, 2
  mov @RightDown_Brick_Column, ecx
  mov ebx, MAP_ROW
  sub ebx, 1
  .if @Hero_Row == MAP_ROW
     mov eax, 1
     ;mov GameState, 4
     ret
  .endif
  invoke GetBrickOrder, @Down_Brick_Row, @Down_Brick_Column
  .if m_Map[ecx].painted == 1
    mov ebx, m_hero.pos.y
    add ebx, HERO_SIZE_Y
    .if ebx >= m_Map[ecx].pos.y
      mov eax, 1
      ret
    .else
      mov eax, 0
      ret
    .endif
  .else
  invoke GetBrickOrder, @LeftDown_Brick_Row, @LeftDown_Brick_Column
  mov edx, m_Map[ecx].pos.x
  add edx, BRICK_SIZE_X
  sub edx, 10
  .if edx >= m_hero.pos.x && m_Map[ecx].painted == 1 && @Hero_Column != 0
    mov edx, m_hero.pos.y
    add edx, HERO_SIZE_Y
    .if edx >= m_Map[ecx].pos.y
      mov eax, 1
      ret
    .endif
  .endif
  invoke GetBrickOrder, @RightDown_Brick_Row, @RightDown_Brick_Column
  mov edx, m_hero.pos.x
  add edx, HERO_SIZE_X
  sub edx, 10
  .if edx >= m_Map[ecx].pos.x && m_Map[ecx].painted == 1 && @Hero_Column != 29
    mov edx, m_hero.pos.y
    add edx, HERO_SIZE_Y
    .if edx >= m_Map[ecx].pos.y
      mov eax, 1
      ret
    .else
      mov eax, 0
      ret
    .endif
  .endif
  .endif
  ret
DetectVBottom endp

ChangeRightSpeed proc
  local tmp_sd:SDWORD
  local @RightBorder:DWORD
  mov eax, WINDOWS_WIDTH
  sub eax, 20
  mov @RightBorder, eax
  pushad

  invoke GetBrickOrder, 0, 0
  mov eax, m_Map[ecx].pos.x
  mov tmp_sd, eax

  mov eax, MAP_COL
  sub eax, 1
  invoke GetBrickOrder, 0, eax
  mov eax, m_Map[ecx].pos.x
  add eax, BRICK_SIZE_X
  .if tmp_sd >= 0 || eax <= @RightBorder
    mov m_hero.speed_x, SPEED_X
    mov BrickXSpeed, 0
  .else
    mov eax, SPEED_X
    neg eax
    mov BrickXSpeed, eax
    mov m_hero.speed_x, 0
  .endif
  mov eax, m_hero.pos.x
  add eax, HERO_SIZE_X
  .if eax >= @RightBorder
    mov BrickXSpeed, 0
    mov m_hero.speed_x, 0
  .endif

  popad
  ret
ChangeRightSpeed endp

ChangeLeftSpeed proc
  local tmp_sd:SDWORD
  local @RightBorder:DWORD
  pushad
  mov eax, WINDOWS_WIDTH
  sub eax, 20
  mov @RightBorder, eax

  invoke GetBrickOrder, 0, 0
  mov eax, m_Map[ecx].pos.x
  mov tmp_sd, eax

  mov eax, MAP_COL
  sub eax, 1
  invoke GetBrickOrder, 0, eax
  mov eax, m_Map[ecx].pos.x
  add eax, BRICK_SIZE_X
  .if tmp_sd >= 0 || eax <= @RightBorder
    mov eax, SPEED_X
    neg eax
    mov m_hero.speed_x, eax
    mov BrickXSpeed, 0
  .else
    mov BrickXSpeed, SPEED_X
    mov m_hero.speed_x, 0
  .endif
  mov eax, m_hero.pos.x
  add eax, HERO_SIZE_X
  .if m_hero.pos.x <= 0
    mov m_hero.speed_x, 0
    mov BrickXSpeed, 0
  .endif

  popad
  ret
ChangeLeftSpeed endp

ChangeUpSpeed proc
  pushad
  call DetectVTop
  .if eax == 0 && m_hero.jumping == 0
    mov BrickYSpeed, SPEED_Y
    mov m_hero.jumping, 1
  .endif
  popad
  ret
ChangeUpSpeed endp


KeyDown proc uses ebx edi esi, hWnd, wParam, lParam
  .if GameState == 1
    .if wParam == VK_UP
      ;人物位置改变
      call ChangeUpSpeed
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_DOWN
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_RIGHT
      invoke ChangeRightSpeed
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_LEFT
      invoke ChangeLeftSpeed
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_SPACE
    ; 点击空格消去方块
    .if ClickedBrickNum == 1
      invoke DropBrick ; 点击一个方块
    .elseif ClickedBrickNum == 0
    .else
      invoke DeleteBrick ; painted 置 0
    .endif
    invoke InvalidateRect, hWnd, NULL, FALSE
    .endif
  .endif
  ret
KeyDown endp

KeyUp proc uses ebx edi esi, hWnd, wParam, lParam
  .if GameState == 1
    .if wParam == VK_UP
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_DOWN
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_RIGHT
      mov BrickXSpeed, 0
      mov m_hero.speed_x, 0
      invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif wParam == VK_LEFT
      mov BrickXSpeed, 0
      mov m_hero.speed_x, 0
      invoke InvalidateRect, hWnd, NULL, FALSE

    .endif
  .endif
  ret
KeyUp endp


ClickNewBrick proc uses ebx edi esi, Brick_row, Brick_column, Brick_order
  local @sright:DWORD
  local @sdown:DWORD
  mov eax, MAP_ROW
  sub eax, 2
  mov @sdown, eax
  mov eax, MAP_COL
  sub eax, 2
  mov @sright, eax

  mov eax, Brick_order
  .if m_Map[eax].color == 4
    ret
  .endif
  .if ClickedBrickNum == 0
    mov eax, Brick_order
    mov m_Map[eax].clicked, 1
    mov ebx, m_Map[eax].color
    mov CurColor, ebx
    mov ClickedBrick[0], eax
    add ClickedBrickNum, 1

  .elseif ClickedBrickNum == 5
  .else
    mov eax, Brick_order
    mov ebx, CurColor
    .if m_Map[eax].color != ebx
      ret
    .endif
    .if Brick_row >= 1 && Brick_column >= 1
      mov edi, Brick_row
      mov esi, Brick_column
      sub edi, 1
      sub esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .else
      .endif
    .endif

    .if Brick_row >= 1
      mov edi, Brick_row
      mov esi, Brick_column
      sub edi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    mov edi, @sright
    .if Brick_row >= 1 && Brick_column <= edi
      mov edi, Brick_row
      mov esi, Brick_column
      sub edi, 1
      add esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    .if Brick_column >= 1
      mov edi, Brick_row
      mov esi, Brick_column
      sub esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    mov edi, @sright
    .if Brick_column <= edi
      mov edi, Brick_row
      mov esi, Brick_column
      add esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    mov edi, @sdown
    .if Brick_row <= edi && Brick_column >= 1
      mov edi, Brick_row
      mov esi, Brick_column
      add edi, 1
      sub esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    mov edi, @sdown
    .if Brick_row <= edi
      mov edi, Brick_row
      mov esi, Brick_column
      add edi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
    mov edi, @sdown
    mov esi, @sright
    .if Brick_row <= edi && Brick_column <= esi
      mov edi, Brick_row
      mov esi, Brick_column
      add edi, 1
      add esi, 1
      invoke GetBrickOrder, edi, esi
      mov eax, ClickedBrickNum
      sub eax, 1
      mov esi, TYPE DWORD
      mul esi
      .if m_Map[ecx].clicked == 1 && ecx == ClickedBrick[eax]
        mov eax, ClickedBrickNum
        mov esi, TYPE DWORD
        mul esi
        mov ecx, Brick_order
        mov ClickedBrick[eax], ecx
        add ClickedBrickNum, 1
        mov eax, Brick_order
        mov m_Map[eax].clicked, 1
        ret
      .endif
    .endif
  .endif
  ret
ClickNewBrick endp

CancelClickedBrick proc uses ebx edi esi, Brick_order
  mov eax, 0
  mov edx, 0
  mov ebx, Brick_order

  .while ClickedBrick[eax] != ebx
    add eax, TYPE DWORD
    add edx, 1
  .endw

  mov ClickedBrickNum, edx

  .while edx < 5
    mov ecx, ClickedBrick[eax]
    mov m_Map[ecx].clicked, 0
    mov ClickedBrick[eax], -1
    add eax, TYPE DWORD
    add edx, 1
  .endw
  ret
CancelClickedBrick endp

DealClickedBrick proc uses ebx edi esi, Brick_row, Brick_column, Brick_order
  mov eax, Brick_order
  .if m_Map[eax].painted == 1
    .if m_Map[eax].clicked == 0
      invoke ClickNewBrick, Brick_row, Brick_column, Brick_order ; 未被点击过：确定方块点击是否有效，加入数组，改变总数量
    .elseif m_Map[eax].clicked == 1
      invoke CancelClickedBrick, Brick_order ; 被点击过，取消点击，清理数组，改变总数量
    .endif
  .endif
  ret
DealClickedBrick endp

ClickBrick proc uses ebx edi esi, Mouse_X, Mouse_Y
  local @Brick_row:DWORD
  local @Brick_column:DWORD
  mov eax, Mouse_Y
  .if SDWORD ptr m_Map[0].pos.y <= eax
    sub eax, m_Map[0].pos.y
    xor edx, edx
    mov ecx, BRICK_SIZE_Y
    div ecx
    mov ebx, eax
    mov eax, Mouse_X
    sub eax, m_Map[0].pos.x
    xor edx, edx
    mov ecx, BRICK_SIZE_X
    div ecx
    mov @Brick_row, ebx
    mov @Brick_column, eax
    invoke GetBrickOrder, @Brick_row, @Brick_column
    invoke DealClickedBrick, @Brick_row, @Brick_column, ecx ; 处理点击的方块
  .endif
  ret
ClickBrick endp

GetHistory proc
  invoke crt_fopen, addr filename, addr szMode
  .if eax == 0
    ret
  .else
    mov edx, eax
    mov ebx, eax
    pushad
    invoke crt_fscanf, edx, addr szText2, addr Best
    popad
    invoke crt_fclose, ebx
  .endif
  ret
GetHistory endp

LButtonDown proc uses eax ebx edi esi, hWnd, wParam, lParam
  local @ptMouse:POINT
  pushad
  mov eax, lParam
  mov ebx, lParam
  shl ebx, 16
  shr ebx, 16
  mov @ptMouse.x, ebx
  shr eax, 16
  mov @ptMouse.y, eax
  .if GameState == 0
      mov eax, @ptMouse.x
      mov ebx, @ptMouse.y
      .if eax <= 196 && ebx >= 486 ;3-说明
          mov GameState, 3
      .elseif eax >= 279 && eax <= 477 && ebx >= 14 && ebx <= 248
          mov GameState, 1
          invoke SetTimer, hWnd, TIMER_ID, TIMER_ELAPSE, NULL ;开启计时器
          invoke GetHistory
      .endif
  .elseif GameState == 1
      invoke ClickBrick, @ptMouse.x, @ptMouse.y  ; 点击方块
  .elseif GameState == 3
      mov GameState, 1
      invoke SetTimer, hWnd, TIMER_ID, TIMER_ELAPSE, NULL ;开启计时器
  .elseif GameState == 2 || GameState == 4
      mov GameState, 0
      invoke CreateHero
      invoke CreateMap
      mov EnergyNum, 15
      mov Score, 0
      invoke InvalidateRect, hWnd, NULL, FALSE
  .endif
  ;鼠标位置判断
  invoke InvalidateRect, hWnd, NULL, FALSE
  popad
  ret
LButtonDown endp

HeroUpdate proc
  ;update hero's position in X
  mov eax, m_hero.speed_x
  add m_hero.pos.x, eax
  ;update hero's position in Y

  ;update hero's curFrameIndex
  add m_hero.curFrameIndex, 1
  .if m_hero.curFrameIndex >= HERO_MAX_FRAME_NUM
    mov m_hero.curFrameIndex, 0
  .endif
  ret
HeroUpdate endp

MapUpdate proc
  local @Down_Brick_Row, @Down_Brick_Column
  local @flag, @temp
  mov @flag, 0
  invoke GetHeroBrick
  add eax, 1
  mov @Down_Brick_Row, eax
  mov @Down_Brick_Column, ecx
  invoke GetBrickOrder, @Down_Brick_Row, @Down_Brick_Column
  mov ebx, m_hero.pos.y
  add ebx, HERO_SIZE_Y
  .if ebx > m_Map[ecx].pos.y && m_Map[ecx].painted == 1
    mov @flag, 1
    ;mov @temp, ebx
    sub ebx, m_Map[ecx].pos.y
    mov @temp, ebx
  .endif
  pushad
    ;更改位置
    mov ecx, MAP_ROW
    xor esi, esi
    L1:
      push ecx
      mov ecx, MAP_COL
      xor ebx, ebx
      xor edx, edx
      L2:
        push edx
        mov eax, RowSize
        mul esi
        pop edx
        add eax, ebx
        push ecx

        mov ecx, BrickXSpeed
        add m_Map[eax].pos.x, ecx

        .if @flag == 0
          mov ecx, BrickYSpeed
          add m_Map[eax].pos.y, ecx
        .else
          push edx
          mov edx, @temp
          add m_Map[eax].pos.y, edx
          pop edx
        .endif

        pop ecx
        xor eax, eax
        add ebx, TYPE Brick
        add edx, 1
        LOOP L2
    add esi, 1
    pop ecx
    LOOP L1
    popad
  ret
MapUpdate endp

SpeedUpdate proc
  local tmp_sd:SDWORD
  local @RightBorder:DWORD
  mov eax, WINDOWS_WIDTH
  sub eax, 20
  mov @RightBorder, eax
  ;边界判断，是否停止地图运动
  pushad
  ;for map left
  invoke  GetBrickOrder, 0, 0
  mov eax, m_Map[ecx].pos.x
  mov tmp_sd, eax
  .if tmp_sd >= 0 && BrickXSpeed > 0
    mov BrickXSpeed, 0
    mov eax, SPEED_X
    neg eax
    mov m_hero.speed_x, eax
  .endif
  .if tmp_sd >= 0 && m_hero.pos.x >= HERO_X && m_hero.speed_x > 0
    mov m_hero.speed_x, 0
    mov eax, SPEED_X
    neg eax
    mov BrickXSpeed, eax
  .endif

  ;for map right
  mov eax, MAP_COL
  sub eax, 1
  invoke GetBrickOrder, 0, eax
  mov eax, m_Map[ecx].pos.x
  add eax, BRICK_SIZE_X
  .if eax <= @RightBorder && BrickXSpeed < 0
    mov m_hero.speed_x, SPEED_X
    mov BrickXSpeed, 0
  .endif
  .if eax <= @RightBorder && m_hero.pos.x <= HERO_X && m_hero.speed_x < 0
    mov m_hero.speed_x, 0
    mov BrickXSpeed, SPEED_X
  .endif

  ;for hero
  .if m_hero.pos.x <= 0 && m_hero.speed_x < 0
    mov m_hero.speed_x, 0
  .endif
  mov eax, m_hero.pos.x
  add eax, HERO_SIZE_X
  .if eax >= @RightBorder && m_hero.speed_x > 0
    mov m_hero.speed_x, 0
  .endif

  ;判断水平方向碰撞
  call DetectH
  .if eax == 1 && (BrickXSpeed > 0 || m_hero.speed_x < 0)
    mov BrickXSpeed, 0
    mov m_hero.speed_x, 0
  .elseif eax == 2 && (BrickXSpeed < 0 || m_hero.speed_x > 0)
    mov BrickXSpeed, 0
    mov m_hero.speed_x, 0
  .endif

  ;判断底部是否悬空
  call DetectVBottom
  .if eax == 1;脚底有方块
    .if BrickYSpeed < 0
      mov BrickYSpeed, 0
      mov m_hero.jumping, 0
    .elseif BrickYSpeed > 0
      mov eax, BrickYSpeed
      sub eax, 1
      mov BrickYSpeed, eax
    .endif
  .else;脚底无方块
    mov eax, BrickYSpeed
    sub eax, 1
    mov BrickYSpeed, eax
  .endif

  ;判断头顶是否有方块
  call DetectVTop
  .if eax == 1
    .if BrickYSpeed > 0
      mov eax, BrickYSpeed
      neg eax
      mov BrickYSpeed, eax
    .endif
  .endif

  popad
  ret
SpeedUpdate endp

GameStateUpdate proc
  pushad
  ;if dead
  .if EnergyNum == 0
      mov GameState, 2
  .endif

  mov ebx, MAP_ROW
  sub ebx, 1
  invoke GetBrickOrder, ebx, 0
  mov eax, m_hero.pos.y
  .if eax > m_Map[ecx].pos.y
    mov GameState, 4
  .endif

  mov ebx, MAP_ROW
  sub ebx, 1
  .while TRUE
    push ebx
    invoke GetBrickOrder, ebx, 0
    pop ebx
    mov eax, m_hero.pos.y
    .if eax >= m_Map[ecx].pos.y
      inc ebx
      mov Score, ebx
      .if ebx > Best
        mov Best, ebx
      .endif
    .endif
    .break .if eax >= m_Map[ecx].pos.y || ebx == 0
    sub ebx, 1
  .endw

  .if ebx == 0
    mov Score, ebx
  .endif
  popad
  ret
GameStateUpdate endp

TimerUpdate proc uses ebx edi esi, hWnd, wParam, lParam
  invoke SpeedUpdate
  invoke MapUpdate
  invoke HeroUpdate
  invoke GameStateUpdate
  invoke InvalidateRect, hWnd, NULL, FALSE

  .if GameState == 2 || GameState == 4
    invoke KillTimer, hWnd, TIMER_ID
  .endif
  ret
TimerUpdate endp

_ProcWinMain proc uses ebx edi esi, hWnd, uMsg,wParam,lParam
  local @stPs:PAINTSTRUCT
  local @stRect:RECT
  local @hDc

  mov eax,uMsg
  .if eax == WM_CREATE
    invoke Init,hWnd,wParam,lParam ;加载各种位图

  .elseif eax == WM_PAINT
    mov @hDc, eax
    .if GameState == 0 ;游戏还未开始
      invoke StartRender,hWnd
    .elseif GameState == 1 ;游戏进行中
      invoke Render,hWnd
    .elseif GameState == 2;游戏结束
      invoke Render,hWnd
    .elseif GameState == 3;游戏说明
      invoke StartRender, hWnd
    .elseif GameState == 4;游戏结束
      invoke Render,hWnd
    .endif

  .elseif eax == WM_KEYDOWN
    invoke KeyDown, hWnd, wParam, lParam

  .elseif eax == WM_KEYUP
    invoke KeyUp, hWnd, wParam, lParam

  .elseif eax == WM_LBUTTONDOWN
    invoke LButtonDown, hWnd, wParam, lParam

  .elseif eax == WM_TIMER
    invoke TimerUpdate, hWnd, wParam, lParam

  .elseif eax == WM_CLOSE
    invoke  DestroyWindow, hWinMain
    invoke  PostQuitMessage, NULL

  .else
    invoke  DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
  .endif

  xor eax,eax
  ret
_ProcWinMain endp

_WinMain proc
  local @stWndClass:WNDCLASSEX
  local @stMsg:MSG

  invoke GetModuleHandle, NULL
  mov hInstance, eax
  invoke RtlZeroMemory, addr @stWndClass, sizeof @stWndClass
;------------------------
;注册窗口类
;------------------------
  invoke LoadIcon, hInstance, ICO_MAIN
  mov @stWndClass.hIcon, eax
  mov @stWndClass.hIconSm, eax

  invoke LoadCursor, 0, IDC_ARROW
  mov @stWndClass.hCursor,eax
  push hInstance
  pop @stWndClass.hInstance
  mov @stWndClass.cbSize, sizeof WNDCLASSEX
  mov @stWndClass.style, CS_HREDRAW or CS_VREDRAW
  mov @stWndClass.lpfnWndProc, offset _ProcWinMain
  mov @stWndClass.hbrBackground, COLOR_WINDOW + 1
  mov @stWndClass.lpszClassName, offset szClassName
  invoke RegisterClassEx, addr @stWndClass
;-----------------------
;建立并显示窗口
;-----------------------
  invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset szClassName, offset szCaptionMain, WS_OVERLAPPEDWINDOW, WINDOWS_X, WINDOWS_Y, WINDOWS_WIDTH, WINDOWS_HEIGHT, NULL, NULL, hInstance, NULL
  mov hWinMain, eax
  invoke ShowWindow, hWinMain, SW_SHOWNORMAL
  invoke UpdateWindow, hWinMain
;-----------------------
;消息循环
;-----------------------
  .while  TRUE
    invoke  GetMessage, addr @stMsg, NULL, 0, 0
  .break .if eax == 0
    invoke  TranslateMessage, addr @stMsg
    invoke  DispatchMessage, addr @stMsg
  .endw
  ret
_WinMain endp

start:
  call _WinMain
  invoke ExitProcess, NULL
  end start
