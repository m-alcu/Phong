.386
.model  flat
.stack 64*1024
locals
assume gs:_TEXT,fs:_TEXT
EXTRN   Debug   :Near
EXTRN   Debug_Run :Near

;######################################################
;######################################################
;#################    M A C R O S  ####################
;######################################################
;######################################################

;######################################################
;write
;######################################################
;Entrada: ebx
;Salida : ninguna
;######################################################
;Escribe en Hexadecimal un número de 32 bits
;######################################################

write           MACRO

                pushad

                mov     eax,ebx

                shld    ebx,eax,4
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq1],bl

                shld    ebx,eax,8
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq2],bl

                shld    ebx,eax,12
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq3],bl

                shld    ebx,eax,16
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq4],bl

                shld    ebx,eax,20
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq5],bl

                shld    ebx,eax,24
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq6],bl

                shld    ebx,eax,28
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq7],bl

                mov     ebx,eax
                and     ebx,0000000Fh
                mov     bl,[ebx + letra]
                mov     [aq8],bl

                mov     edx,Offset texto
                mov     ah,9
                int     21h

                popad

                ENDM

;######################################################
;write2
;######################################################
;Entrada: ninguna
;Salida : ninguna
;######################################################
;Escribe el texto indicado en el offset texto2
;######################################################


write2          MACRO

                pushad

                mov     edx,Offset texto2
                mov     ah,9
                int     21h

                popad

                ENDM

;######################################################
;edge
;######################################################
;Entrada: 2 puntos con sus respectivas normales
;Salida : linea entre los puntos con normales
;######################################################
;Escribe una linea recta interpolanto las normales
;######################################################


edge            MACRO   xx1,xx2,uu1,uu2,vv1,vv2,yy1,yy2
                LOCAL   @@cero,@@next_scan

                movzx   edi,[yy2]
                sub     di,[yy1]
                jz      @@cero

                xor     eax,eax
                xor     ecx,ecx
                mov     ah,[vv2]
                mov     ch,[vv1]
                sub     ah,ch
                cwd
                idiv    di

                mov     ebp,eax
                shl     ecx,16
                shl     ebp,16

                xor     eax,eax
                mov     ah,[uu2]
                mov     ch,[uu1]
                sub     ah,ch
                cwd
                idiv    di
                cwde
                add     ebp,eax

                mov     ax,[xx2]
                mov     bx,[xx1]
                sub     ax,bx
                shl     eax,16
                shl     ebx,16
                mov     bx,8000h
                cdq
                idiv    edi

                mov     edx,ebx
@@next_scan:    shr     edx,16
                mov     [esi],dx
                mov     [esi+2],ecx
                add     ebx,eax
                add     esi,6
                mov     edx,ebx
                add     ecx,ebp
                dec     di
                jnz     @@next_scan
@@cero:
                ENDM

;######################################################
;tri_fill
;######################################################
;Entrada: Perímetro izquierdo y derecho de un triángulo
;Salida : un triángulo
;######################################################
;Escribe una linea recta interpolanto las normales
;######################################################

tri_fill        MACRO
                LOCAL @@next_line, @@ordered, @@cont

                xor     edi,edi
                xor     ecx,ecx
                xor     ebp,ebp

                mov     cx,[y3]
                mov     di,[y1]
                sub     ecx,edi

                shl     edi,6
                lea     edi,[edi+4*edi]

                add     edi,[OFF_tmp]

@@next_line:    push    ecx

                mov     bp,[esi+1200]
                mov     cx,[esi]
                sub     bp,cx
                jle     @@cont

                xor     eax,eax
                mov     ax,[esi+2]
                mov     bx,[esi+1202]
                sub     ax,bx
                shl     ebx,16
                cwd
                idiv    bp

                mov     edx,eax
                shl     edx,16

                xor     eax,eax
                mov     ax,[esi+4]
                mov     bx,[esi+1204]
                sub     ax,bx
                cwd
                idiv    bp

                cwde
                xor     dx,dx
                add     edx,eax

                mov     eax,ebx

                add     edi,ecx

@@next_pixel:   shr     ebx,16
                mov     bl,ah
                mov     bl,[ebx + light]
                add     eax,edx
                mov     [edi+ebp],bl
                mov     ebx,eax
                dec     ebp
                jnz     @@next_pixel

                sub     edi,ecx
@@cont:         add     esi,6
                add     edi,320
                pop     ecx
                dec     ecx
                jnz     @@next_line

                ENDM


;######################################################
;edge2
;######################################################
;Entrada: 2 puntos con sus respectivas normales
;Salida : linea entre los puntos con normales
;######################################################
;Escribe una linea recta interpolanto las normales
;en este caso haciendo cliping del triangulo en una
;ventana de 320x200 pixeles
;######################################################

edge2           MACRO   xx1,xx2,uu1,uu2,vv1,vv2,yy1,yy2
                LOCAL   @@cero, @@next_scan, @@skip_scan

                movsx   edi,[yy2]
                movsx   edx,[yy1]

                cmp     edi,0           ; yy2 <= 0   ==> no tracear
                jle     @@cero
                cmp     edx,200         ; yy1 >  200 ==> no tracear
                jg      @@cero

                sub     di,dx
                jz      @@cero

                xor     eax,eax
                xor     ecx,ecx
                mov     ah,[vv2]
                mov     ch,[vv1]
                sub     ah,ch
                cwd
                idiv    di

                mov     ebp,eax
                shl     ecx,16
                shl     ebp,16

                xor     eax,eax
                mov     ah,[uu2]
                mov     ch,[uu1]
                sub     ah,ch
                cwd
                idiv    di
                cwde
                add     ebp,eax

                mov     ax,[xx2]
                mov     bx,[xx1]
                sub     ax,bx
                shl     eax,16
                shl     ebx,16
                mov     bx,8000h
                cdq
                idiv    edi
                movsx   edi,[yy1]

                mov     edx,ebx
@@next_scan:    shr     edx,16
                cmp     edi,200
                jae     @@skip_scan
                mov     [esi],dx
                mov     [esi+2],ecx
                add     esi,6
@@skip_scan:    add     ebx,eax
                mov     edx,ebx
                add     ecx,ebp
                inc     edi
                cmp     di,[yy2]
                jnz     @@next_scan
@@cero:
                ENDM

;######################################################
;tri_fill2
;######################################################
;Entrada: Perímetro izquierdo y derecho de un triángulo
;Salida : un triángulo
;######################################################
;Escribe una linea recta interpolanto las normales
;en este caso haciendo cliping del triangulo en una
;ventana de 320x200 pixeles
;######################################################


tri_fill2       MACRO
                LOCAL @@next_line, @@ordered, @@cont, @@skip_pixel, @@next_pixel

                xor     ebp,ebp

                movsx   ecx,[y3]
                movsx   edi,[y1]

                cmp     di,0            ; y1 >= 0
                jge     @@no_clip_y1
                xor     edi,edi
@@no_clip_y1:
                cmp     cx,200          ; y3 <= 200
                jle     @@no_clip_y3
                mov     ecx,200
@@no_clip_y3:
                sub     ecx,edi

                shl     edi,6
                lea     edi,[edi+4*edi]

                add     edi,[OFF_tmp]

@@next_line:    push    ecx

                movsx   ebp,word ptr [esi+1200]
                movsx   ecx,word ptr [esi]
; bp=x2
; cx=x1
;=======================================
                cmp     cx,320          ; x1 >= 320 ==> no scanear
                jge     @@cont
                cmp     bp,0            ; x2 <  0   ==> no scanear
                jl      @@cont
;=======================================

                sub     ebp,ecx
                jle     @@cont

                xor     eax,eax
                mov     ax,[esi+2]
                mov     bx,[esi+1202]
                sub     ax,bx
                shl     ebx,16
                cwd
                idiv    bp

                mov     edx,eax
                shl     edx,16

                xor     eax,eax
                mov     ax,[esi+4]
                mov     bx,[esi+1204]
                sub     ax,bx
                cwd
                idiv    bp

                cwde
                xor     dx,dx
                add     edx,eax

                mov     eax,ebx

                push    edi
                add     edi,ecx
                add     ecx,ebp         ; ecx=x2

@@next_pixel:   cmp     cx,320
                jae     @@skip_pixel

                shr     ebx,16
                mov     bl,ah
                mov     bl,[ebx + light]
                mov     [edi+ebp],bl

@@skip_pixel:   dec     ecx
                add     eax,edx
                mov     ebx,eax
                dec     ebp
                jnz     @@next_pixel

                pop     edi
@@cont:         add     esi,6
                add     edi,320
                pop     ecx
                dec     ecx
                jnz     @@next_line

                ENDM




;
; Hace la matriz de rotaciones ( 9 mults por rotacion )
;

;######################################################
;Make_Mx
;######################################################
;Entrada: los 3 angulos espaciales de rotacion xan,yan,zan
;Salida : la matriz de rotación r00,r01,r02,r10,r11,r12,r20,r21,r22
;######################################################
;A partir de los 3 angulos calcula la matriz que transforma
;un punto en el punto rotado segun los 3 angulos
;######################################################

Make_Mx         MACRO

;primero calculo los senos y consenos iniciales

                cli

                mov     esi,[xan]
                mov     eax,dword ptr seno[4*esi+4096]
                mov     [cos1],eax
                mov     eax,dword ptr seno[4*esi]
                mov     [sin1],eax

                mov     esi,[yan]
                mov     eax,dword ptr seno[4*esi+4096]
                mov     [cos2],eax
                mov     eax,dword ptr seno[4*esi]
                mov     [sin2],eax

                mov     esi,[zan]
                mov     eax,dword ptr seno[4*esi+4096]
                mov     [cos3],eax
                mov     eax,dword ptr seno[4*esi]
                mov     [sin3],eax

                sti

                mov     eax,[sin2]
                imul    [cos3]
                shrd    eax,edx,16
                mov     [sin2cos3],eax

                mov     eax,[sin2]
                imul    [sin3]
                shrd    eax,edx,16
                mov     [sin2sin3],eax
;
;Fila: r00, r01, r02
;
                mov     eax,[cos2]            ;c2*c3
                imul    [cos3]
                shrd    eax,edx,16
                mov     [r00],eax

                mov     eax,[cos2]            ;c2*s3
                imul    [sin3]
                shrd    eax,edx,16
                mov     [r01],eax

                mov     eax,[sin2]            ;s2
                mov     [r02],eax
;
;Fila: r10, r11, r12
;
                mov     eax,[sin1]            ;-s1*s2*c3
                neg     eax
                imul    [sin2cos3]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,[sin3]            ;-s3*c1
                neg     eax
                imul    [cos1]
                add     ebx,eax
                adc     ecx,edx
                shrd    ebx,ecx,16
                mov     [r10],ebx

                mov     eax,[sin1]            ;-s1*s2*s3
                neg     eax
                imul    [sin2sin3]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,[cos1]            ;c1*c3
                imul    [cos3]
                add     ebx,eax
                adc     ecx,edx
                shrd    ebx,ecx,16
                mov     [r11],ebx

                mov     eax,[cos2]            ;s1*c2
                imul    [sin1]
                shrd    eax,edx,16
                mov     [r12],eax
;
;Fila: r20, r21, r22
;
                mov     eax,[cos1]            ;-c1*s2*c3
                neg     eax
                imul    [sin2cos3]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,[sin1]            ;s1*s3
                imul    [sin3]
                add     ebx,eax
                adc     ecx,edx
                shrd    ebx,ecx,16
                mov     [r20],ebx


                mov     eax,[cos1]            ;-c1*s2*s3
                neg     eax
                imul    [sin2sin3]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,[cos3]            ;-c3*s1
                neg     eax
                imul    [sin1]
                add     ebx,eax
                adc     ecx,edx
                shrd    ebx,ecx,16
                mov     [r21],ebx


                mov     eax,[cos1]            ;c1*c2
                imul    [cos2]
                shrd    eax,edx,16
                mov     [r22],eax

                ENDM

;
; Rota un punto (formato 16.16) en 9 mults
;

;##################
;Rotate_vert
;##################

Rotate_vert     MACRO   ; rotacion vertice ( 3 ejes )

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Calculo px, py, pz³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     esi,[OFF_p1]
                mov     ebp,[esi]
                mov     edi,[esi+4]
                mov     esi,[esi+8]

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Coordenada px rotada³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     eax,ebp
                imul    [r00]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,edi
                imul    [r01]
                add     ebx,eax
                adc     ecx,edx

                mov     eax,esi
                imul    [r02]
                add     eax,ebx
                adc     edx,ecx

                shrd    eax,edx,16
                mov     [px],eax
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Coordenada py rotada³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     eax,ebp
                imul    [r10]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,edi
                imul    [r11]
                add     ebx,eax
                adc     ecx,edx

                mov     eax,esi
                imul    [r12]
                add     eax,ebx
                adc     edx,ecx

                shrd    eax,edx,16
                mov     [py],eax
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Coordenada pz rotada³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     eax,ebp
                imul    [r20]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,edi
                imul    [r21]
                add     ebx,eax
                adc     ecx,edx

                mov     eax,esi
                imul    [r22]
                add     eax,ebx
                adc     edx,ecx

                shrd    eax,edx,16
                mov     [pz],eax

                ENDM

;
; Proyecta un vertice de 3D a 2D (en 2 div's)
;

;##################
;Proyect_vert
;##################


Proyect_vert    MACRO

                mov     esi,[OFF_p2]

                mov     ecx,[pz]                ; Z
                add     ecx,[scale]             ; escala
                or      ecx,ecx
                jnz     @@no_es_cero
                mov     ecx,1
@@no_es_cero:
                mov     eax,[px]                ; X
                cdq
                shld    edx,eax,8               ; X=X*256
                shl     eax,8
                idiv    ecx

                add     ax,[posx]
                mov     [esi],ax               ; colocamos X

                mov     eax,[py]                ; Y
                cdq
                shld    edx,eax,8               ; Y=Y*256
                shl     eax,8
                idiv    ecx

                add     ax,[posy]
                mov     [esi+2],ax              ; colocamos Y

                sar     ecx,2                   ; Z=Z/4
                mov     [esi+8],ecx

                ENDM

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ Rota la normal ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾

;##################
;Rotate_normal
;##################

Rotate_normal   MACRO   ; rotacion normal

                mov     esi,[OFF_p1]
                sub     esi,[OFF_verts]
                add     esi,[OFF_normals]
                mov     ebp,[esi]
                mov     edi,[esi+4]
                mov     esi,[esi+8]

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Coordenada nx rotada³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     eax,ebp
                imul    [r00]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,edi
                imul    [r01]
                add     ebx,eax
                adc     ecx,edx

                mov     eax,esi
                imul    [r02]
                add     eax,ebx
                adc     edx,ecx

                shrd    eax,edx,24
                mov     ebx,[OFF_p2]
                sar     al,1
                add     al,80h
                mov     [ebx+4],al
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Coordenada ny rotada³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     eax,ebp
                imul    [r10]
                mov     ebx,eax
                mov     ecx,edx

                mov     eax,edi
                imul    [r11]
                add     ebx,eax
                adc     ecx,edx

                mov     eax,esi
                imul    [r12]
                add     eax,ebx
                adc     edx,ecx

                shrd    eax,edx,24
                mov     ebx,[OFF_p2]
                sar     al,1
                add     al,80h
                mov     [ebx+5],al

                ENDM


;.code
.data

;######################################################
;######################################################
;############## V A R I A B L E S  ####################
;######################################################
;######################################################

;### auxiliares para escribir en consola ###

letra   db      "0123456789ABCDEF"
texto   LABEL   BYTE
aq1      db      ?
aq2      db      ?
aq3      db      ?
aq4      db      ?
aq5      db      ?
aq6      db      ?
aq7      db      ?
aq8      db      ?,"-$"

texto2   db      10,13,"$"

;### relleno de triangulos ###

y1uv    LABEL   DWORD   ;u,v phong shading
y1      DW      20
u1      DB      0
v1      DB      0

y2uv    LABEL   DWORD
y2      DW      40
u2      DB      100
v2      DB      0

y3uv    LABEL   DWORD
y3      DW      40
u3      DB      100
v3      DB      100

x1ab    LABEL   DWORD   ;a,b futuro texture mapping
x1      DW      0
a1      DB      0
b1      DB      0

x2ab    LABEL   DWORD
x2      DW      -10
a2      DB      0
b2      DB      0

x3ab    LABEL   DWORD
x3      DW      10
a3      DB      0
b3      DB      0

buffer  LABEL   WORD
        DW     1200     dup(0)  ; buffer para guardar los edges

light   LABEL   BYTE
        include light.inc       ; environment mapping
        db      0

;### carga de objetos y estructuras ###

Obj_name        db      "object.r3d",0,0,0,0,0,0
File_handle     dw      0

N_verts         dd      0
N_faces         dd      0

OFF_verts       dd      0
OFF_normals     dd      0
OFF_faces       dd      0
OFF_bin         dd      0
OFF_tmp         dd      0
OFF_tga         dd      0
OFF_back        dd      0

OFF_verts2      dd      0

Error1          db      "Error en el modulo carga y alocacion!",10,13,"$"


STR_face        LABEL   BYTE
        STR_number      dw      0
        STR_color       dw      0
        STR_normal      dw      0
        STR_index1      dw      0
        STR_index2      dw      0
        STR_index3      dw      0
        STR_comando     dw      0

paleta          LABEL   BYTE
        include         paleta.inc

palgold         LABEL   BYTE
        include         gold.inc

palsilver       LABEL   BYTE
        include         silver.inc


;### variables de operaciones espaciales de puntos ###

xan             dd      0
yan             dd      0
zan             dd      0

xinc            dd      2
yinc            dd      2
zinc            dd      0


cos1            dd      0
cos2            dd      0       ; prec lculos
cos3            dd      0

sin1            dd      0
sin2            dd      0
sin3            dd      0

sin2sin3        dd      0
sin2cos3        dd      0

OFF_p1          dd      0
OFF_p2          dd      0

r00             dd      0
r01             dd      0
r02             dd      0
r10             dd      0
r11             dd      0
r12             dd      0       ; matriz de rotacion 3d
r20             dd      0
r21             dd      0
r22             dd      0

px              dd      0
py              dd      0
pz              dd      0

scale3          dd      0
scale           dd      270*65536
scale16         dd      0

posx            dw      160
posy            dw      300

z_minima        dd      20*65536
radio           dd      200
log             dd      0

seno    LABEL   DWORD
        include     sincos.inc  ; tabla del seno y coseno
                                ; 4096*4 bytes de ancho


;### carga del bitmap de fondo ###

TGA_name        db      "2000.tga",0
TGA_handle      dw      0

Error2          db      "Error en el modulo carga TGA!",10,13,"$"

Cabecera        db      18      dup(0)

color_tapiz     LABEL   BYTE
                db      768     dup(0)


;### generales ###

End_Message     db      "ş Realtime Phong Shading (Environment mapping)",10,13
                db      "  released by Martin Alcubierre 1996 for Public "
                db      "Domain",10,13
                db      "ş Keys: Q-A,W-S,E-D,R-F,T-G,1-2-3",10,13
                db      "ş Thanks to Jorge Cabeza Garcia for ASC2R3D :)"
                db      10,13,"$"


BPA             dd      ?
VGA_off         dd      ?
salto           dd      200


.code

;##################
;Control
;##################
;Modulo de control del objeto 3D y de todas las opciones
;##################

Control         PROC

                xor     ah,ah
                int     16h

                cmp     al,"q"          ; acercarse
                jnz     @@next1
                mov     ebx,[scale16]
                sub     [scale],ebx
                jmp     @@key

@@next1:        cmp     al,"a"          ; alejarse
                jnz     @@next2
                mov     ebx,[scale16]
                add     [scale],ebx
                jmp     @@key

@@next2:        cmp     al,"w"          ; aumentar velocidad de giro x
                jnz     @@next3
                mov     eax,[xinc]
                shl     eax,1
                mov     [xinc],eax
                jmp     @@key

@@next3:        cmp     al,"s"          ; disminuir velocidad de giro x
                jnz     @@next4
                mov     eax,[xinc]
                shr     eax,1
                mov     [xinc],eax
                jmp     @@key

@@next4:        cmp     al,"e"          ; aumentar velocidad de giro y
                jnz     @@next5
                mov     eax,[yinc]
                shl     eax,1
                mov     [yinc],eax
                jmp     @@key

@@next5:        cmp     al,"d"          ; disminuir velocidad de giro y
                jnz     @@next6
                mov     eax,[yinc]
                shr     eax,1
                mov     [yinc],eax
                jmp     @@key
@@next6:
                cmp     al,"r"          ; movimiento a la derecha
                jnz     @@next7
                sub     [posx],20
                jmp     @@key

@@next7:        cmp     al,"f"          ; movimiento a la izquierda
                jnz     @@next8
                add     [posx],20
                jmp     @@key
@@next8:
                cmp     al,"t"          ; movimiento abajo
                jnz     @@next9
                sub     [posy],20
                jmp     @@key

@@next9:        cmp     al,"g"          ; movimiento arriba
                jnz     @@next10
                add     [posy],20
                jmp     @@key

@@next10:       cmp     al,"1"          ; paleta normal
                jnz     @@next11
                call    SetPaleta
                jmp     @@key

@@next11:       cmp     al,"2"          ; paleta gold
                jnz     @@next12
                call    SetPalGold
                jmp     @@key

@@next12:       cmp     al,"3"          ; paleta silver
                jnz     @@next13
                call    SetPalSilver
                jmp     @@key

@@next13:
                xor     eax,eax
                ret

@@key:

                mov     eax,[scale]     ; scale3 = 3/4 * scale
                shr     eax,2
                mov     ebx,eax
                add     eax,eax
                add     eax,ebx
                mov     [scale3],eax

;               bsr     eax,eax
;               sub     eax,15
;               mov     [log],eax

                mov     eax,1
                ret

Control         ENDP

;##################
;write
;##################

clearVGA        PROC

                pushad

                mov     ecx,(64000/4)
                xor     edx,edx
                mov     esi,[OFF_tmp]
                mov     edi,[VGA_off]
                mov     ebx,[OFF_back]
@@next_4pixels:
                mov     eax,[esi+edx]
                mov     [edi+edx],eax
                mov     eax,[ebx+edx]
                mov     [esi+edx],eax
                add     edx,4
                dec     ecx
                jnz     @@next_4pixels

                popad
                ret

clearVGA        ENDP

SetPaleta       PROC

                mov     edx,3c8h
                xor     al,al
                out     dx,al
                inc     edx
                mov     esi,OFFSET paleta
                mov     ecx,768
@@nn:           mov     al,[esi]
                inc     esi
                out     dx,al
                dec     ecx
                jnz     @@nn
                ret

SetPaleta       ENDP

SetPalGold      PROC

                mov     edx,3c8h
                xor     al,al
                out     dx,al
                inc     edx
                mov     esi,OFFSET palgold
                mov     ecx,768
@@nn:           mov     al,[esi]
                inc     esi
                out     dx,al
                dec     ecx
                jnz     @@nn
                ret

SetPalGold      ENDP

SetPalSilver    PROC

                mov     edx,3c8h
                xor     al,al
                out     dx,al
                inc     edx
                mov     esi,OFFSET palsilver
                mov     ecx,768
@@nn:           mov     al,[esi]
                inc     esi
                out     dx,al
                dec     ecx
                jnz     @@nn
                ret

SetPalSilver    ENDP


Vsync           PROC

                mov     dx,03dah
@@esp1:
                in      al,dx
                test    al,8
                jnz     @@esp1
@@esp2:
                in      al,dx
                test    al,8
                jz      @@esp2
                ret

Vsync           ENDP

auto_scale      PROC

                mov     esi,[OFF_verts]
                mov     ecx,[N_verts]
                lea     ecx,[ecx*2+ecx]         ;ecx=ecx*3
                xor     ebp,ebp

@@next_p:       mov     eax,[esi]
                cdq
                xor     eax,edx
                sub     eax,edx                 ;eax=ABS([esi])

                cmp     ebp,eax
                jae     @@no_swap
                xchg    ebp,eax
@@no_swap:
                add     esi,4
                dec     ecx
                jnz     @@next_p

                mov     [radio],ebp

                mov     ebx,[radio]
                write

                lea     ebp,[ebp*2+ebp]
                mov     [scale],ebp     ; scale = radio * 3

                mov     ebx,ebp
                write

                shr     ebp,4
                mov     [scale16],ebp
                mov     [z_minima],ebp

                mov     eax,[scale]     ; scale3 = 3/4 * scale
                shr     eax,2
                mov     ebx,eax
                add     eax,eax
                add     eax,ebx
                mov     [scale3],eax

                mov     ebx,eax
                write

                mov     eax,[radio]
                bsr     ecx,eax

                mov     ebx,ecx
                write

                sub     ecx,14
                mov     [log],ecx

                mov     ebx,ecx
                write
                write2


                ret
auto_scale      ENDP

set_name        PROC
                ; en edi esta el comienzo de la cadena

@@comienzo:     inc     edi
                cmp     byte ptr   [edi],'C'
                jnz     @@comienzo
                cmp     byte ptr   [edi+1],'M'
                jnz     @@comienzo
                cmp     byte ptr   [edi+2],'D'
                jnz     @@comienzo
                cmp     byte ptr   [edi+3],'L'
                jnz     @@comienzo
                cmp     byte ptr   [edi+4],'I'
                jnz     @@comienzo
                cmp     byte ptr   [edi+5],'N'
                jnz     @@comienzo
                cmp     byte ptr   [edi+6],'E'
                jnz     @@comienzo
                cmp     byte ptr   [edi+7],'='
                jnz     @@comienzo
                add     edi,7

@@comienzo2:    inc     edi
                cmp     byte ptr   [edi],0
                jz      @@exit
                cmp     byte ptr   [edi],' '
                jnz     @@comienzo2

                inc     edi
                mov     esi,edi
                mov     edi,OFFSET Obj_name
                mov     ecx,12
                cld
                rep     movsb
@@exit:
                ret
                ENDP


set_name_xp     PROC

                mov	edi,esi
                add	edi,80h

                ; en edi esta el comienzo de la cadena

                cmp     byte ptr [edi],0	;si es 0 no hay parametro
                jz      @@exit
                mov	    ecx,0
                mov	    cl,byte ptr [edi]
@@comienzo4:    inc     edi
                cmp     byte ptr   [edi],0
                jz      @@exit
                cmp     byte ptr   [edi],' '
                jnz     @@comienzo4
                inc     edi
                dec	    ecx
                mov	    esi,OFFSET Obj_name

@@continuar:	  cmp	    byte ptr   [edi],' '
                jz      @@final4	
                mov	    al,byte ptr [edi]
                mov	    byte ptr [esi],al
                inc	    edi
                inc	    esi
                dec	    ecx
                jnz     @@continuar
@@final4:	      mov     byte ptr [esi],0

@@exit:
                ret
                ENDP


;##################
;ph_fill
;##################


phong_fill      PROC

                cmp     bp,di
                jle     @@not_swapy
                xchg    ebp,edi
                xchg    eax,ebx
@@not_swapy:    cmp     di,si
                jle     @@orderedy
                xchg    edi,esi
                xchg    ebx,ecx
                cmp     bp,di
                jle     @@orderedy
                xchg    ebp,edi
                xchg    eax,ebx
@@orderedy:
                cmp     ax,320          ; x1 fuera
                jae     @@clipx
                cmp     bx,320          ; x2 fuera
                jae     @@clipx
                cmp     cx,320          ; x3 fuera
                jae     @@clipx
                cmp     bp,200          ; y1 fuera
                ja      @@clipy
                cmp     di,200          ; y2 fuera
                ja      @@clipy
                cmp     si,200          ; y3 fuera
                ja      @@clipy

;===========================================================
                mov     [y1uv],ebp
                mov     [y2uv],edi
                mov     [y3uv],esi
                mov     [x1ab],eax
                mov     [x2ab],ebx
                mov     [x3ab],ecx

                and     eax,0000FFFFh   ;ecx=p1x
                and     ebx,0000FFFFh   ;ebx=p2x
                and     ecx,0000FFFFh   ;eax=p3x

                sub     ecx,eax         ;ecx=p31x
                sub     ebx,eax         ;ebx=p21x
                lea     esi,[si]
                lea     edi,[di]
                sub     si,bp           ;ecx=p31y
                sub     di,bp           ;edx=p21y
                imul    ecx,edi         ;ecx=p31x*p21y
                imul    ebx,esi         ;ebx=p21x*p31y
                mov     esi,OFFSET buffer
                mov     ebp,OFFSET buffer + 1200

                sub     ecx,ebx
                jz      @@fin
                jl      @@no_change

                xchg    ebp,esi

@@no_change:    push    ebp

                edge    x1,x3,u1,u3,v1,v3,y1,y3
                pop     esi
                edge    x1,x2,u1,u2,v1,v2,y1,y2
                edge    x2,x3,u2,u3,v2,v3,y2,y3
                mov     esi,OFFSET buffer
                tri_fill
@@fin:
                ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³aqui debe llegar cuando el poligono esta parcial o totalmente cortado³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

@@clipx:
                pushad

                cmp     ax,bx
                jle     @@not_swapx
                xchg    eax,ebx
@@not_swapx:    cmp     bx,cx
                jle     @@orderedx
                xchg    ebx,ecx
                cmp     ax,bx
                jle     @@orderedx
                xchg    eax,ebx
@@orderedx:
                cmp     ax,320          ; x1 >= 320 ==> fuera totalmente
                jge     @@fin2
                cmp     cx,0            ; x3 <  0   ==> fuera totalmente
                jl      @@fin2

                popad

@@clipy:
                cmp     bp,200          ; y1 >= 200 ==> fuera totalmente
                jge     @@fin
                cmp     si,0            ; y3 <= 0   ==> fuera totalmente
                jle     @@fin

;===========================================================
                mov     [y1uv],ebp
                mov     [y2uv],edi
                mov     [y3uv],esi
                mov     [x1ab],eax
                mov     [x2ab],ebx
                mov     [x3ab],ecx

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³aqui el poligono esta parcialmente en la pantalla³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

                movsx   eax,ax          ;ecx=p1x
                movsx   ebx,bx          ;ebx=p2x
                movsx   ecx,cx          ;eax=p3x

                sub     ecx,eax         ;ecx=p31x
                sub     ebx,eax         ;ebx=p21x
                movsx   esi,si
                movsx   edi,di
                movsx   ebp,bp
                sub     esi,ebp         ;ecx=p31y
                sub     edi,ebp         ;edx=p21y
                imul    ecx,edi         ;ecx=p31x*p21y
                imul    ebx,esi         ;ebx=p21x*p31y
                mov     esi,OFFSET buffer
                mov     ebp,OFFSET buffer + 1200

                sub     ecx,ebx
                jz      @@fin
                jl      @@no_change2

                xchg    ebp,esi

@@no_change2:   push    ebp

                edge2   x1,x3,u1,u3,v1,v3,y1,y3
                pop     esi
                edge2   x1,x2,u1,u2,v1,v2,y1,y2
                edge2   x2,x3,u2,u3,v2,v3,y2,y3
                mov     esi,OFFSET buffer
                tri_fill2
                ret
@@fin2:
                popad
                ret

phong_fill      ENDP

;##################
;load3d
;##################

load3d          PROC

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se abre el fichero objeto³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,3d00h
                mov     edx,OFFSET Obj_name
                int     21h
                jc      @@error_load
                mov     [File_handle],ax
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se lee el numero de verts³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[File_handle]
                mov     ecx,2
                mov     edx,OFFSET N_verts
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se lee el numero de faces³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[File_handle]
                mov     ecx,2
                mov     edx,OFFSET N_faces
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se aloca 12*N_verts bytes a OFF_verts³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,[N_verts]
                imul    edx,12
                int     31h
                jc      @@error_load
                mov     [OFF_verts],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se aloca 12*N_verts bytes a OFF_verts2³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,[N_verts]
                imul    edx,12
                int     31h
                jc      @@error_load
                mov     [OFF_verts2],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se leen los 12*N_verts y se cargan en OFF_verts³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[File_handle]
                mov     ecx,[N_verts]
                mov     edx,[OFF_verts]
@@next_3p:      pushad
                mov     ecx,12
                int     21h
                jc      @@error_load
                popad

                mov     ebp,[edx]
                shl     ebp,16
                mov     [edx],ebp

                mov     ebp,[edx+4]
                shl     ebp,16
                mov     [edx+4],ebp

                mov     ebp,[edx+8]
                shl     ebp,16
                mov     [edx+8],ebp





                add     edx,12
                dec     ecx
                jnz     @@next_3p

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se aloca 12*N_verts bytes a OFF_normals³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,[N_verts]
                imul    edx,12
                int     31h
                jc      @@error_load
                mov     [OFF_normals],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se leen los 12*N_verts y se cargan en OFF_normals³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[File_handle]
                mov     ecx,[N_verts]
                mov     edx,[OFF_normals]
@@next_3n:      pushad
                mov     ecx,12
                int     21h
                jc      @@error_load
                popad
                add     edx,12
                dec     ecx
                jnz     @@next_3n
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se aloca 16*N_faces bytes³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,[N_faces]
                shl     edx,4
                int     31h
                jc      @@error_load
                mov     [OFF_faces],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se carga la estructura de los planos ( clusters de 14 -> 16 bytes )³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ecx,[N_faces]
                mov     edi,[OFF_faces]
@@next_face:    push    ecx
                push    edi
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Lee un cluster de 14 bytes ( se suponen triangulos )³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[File_handle]
                mov     ecx,14
                mov     edx,OFFSET STR_face
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Graba un cluster de 16 bytes en memoria ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                pop     edi
                movzx   eax,word ptr [STR_index1]
                imul    eax,12
                add     eax,[OFF_verts2]
                mov     [edi],eax
                movzx   eax,word ptr [STR_index2]
                imul    eax,12
                add     eax,[OFF_verts2]
                mov     [edi+4],eax
                movzx   eax,word ptr [STR_index3]
                imul    eax,12
                add     eax,[OFF_verts2]
                mov     [edi+8],eax
                xor     eax,eax
                mov     [edi+12],eax

                add     edi,16
                pop     ecx
                dec     ecx
                jnz     @@next_face
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Aloca 65536*4*2 bytes para el BINSORT³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,(65536*4*2)
                int     31h
                jc      @@error_load
                mov     [OFF_bin],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Aloca 65536 bytes para el tapiz TGA ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,65536
                int     31h
                jc      @@error_load
                mov     [OFF_tga],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Aloca 64000 bytes para el fondo ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,64000
                int     31h
                jc      @@error_load
                mov     [OFF_back],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Aloca 64000 bytes para la pantalla³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,0ee42h
                mov     edx,64000
                int     31h
                jc      @@error_load
                mov     [OFF_tmp],edx
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se pone a 0's la zona de memoria de los BINS³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ecx,(65536*4*2)/4
                mov     edi,[OFF_BIN]
                xor     eax,eax
                rep     stosd
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se cierra el fichero objeto³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3eh
                mov     bx,[File_handle]
                int     21h
                jc      @@error_load
                ret

@@error_load:   mov     ax,3
                int     10h

                mov     edx, OFFSET Error1
                mov     ah,9
                int     21h

                mov   ax,4C00h
                int   21h

load3d          ENDP

;##################
;3d
;##################


;
; Calcula los nuevos verts y normales del objeto rotado
;

Set_verts       PROC

                Make_Mx

                mov     ecx,[N_verts]

                mov     eax,[OFF_verts]
                mov     ebx,[OFF_verts2]
                mov     [OFF_p1],eax
                mov     [OFF_p2],ebx

@@next_vert:    push    ecx

                Rotate_vert
                Proyect_vert
                Rotate_normal

                add     [OFF_p1],12
                add     [OFF_p2],12

                pop     ecx
                dec     ecx
                jnz     @@next_vert
                ret

Set_verts       ENDP

;
; Selecciona los planos que se ven en el buffer de BINS
;

Pick_faces      PROC

                mov     ecx,[N_faces]
                mov     edi,[OFF_faces]         ; puntero al plano

@@next_face:    push    ecx
                push    edi

                mov     esi,[edi]               ; esi=puntero a p1
                movsx   ebp,word ptr [esi]      ; ebp=p1x
                movsx   eax,word ptr [esi+2]    ; eax=p1y
                mov     edx,[esi+8]             ; edx=p1z/4

                mov     esi,[edi+4]             ; esi=puntero a p2
                movsx   ebx,word ptr [esi]      ; ebx=p2x
                movsx   ecx,word ptr [esi+2]    ; ecx=p2y
                add     edx,[esi+8]             ; edx=(p1z+p2z)/4

                mov     esi,[edi+8]             ; esi=puntero a p3
                movsx   edi,word ptr [esi]      ; edi=p3x
                add     edx,[esi+8]             ; edx=(p1z+p2z+p3z)/4
                movsx   esi,word ptr [esi+2]    ; esi=p3y

                sub     edi,ebx         ;edi=p32x
                sub     ebx,ebp         ;ebx=p21x
                sub     esi,ecx         ;esi=p32y
                sub     ecx,eax         ;ecx=p21y

                imul    ecx,edi         ;edx=p32x*p21y
                imul    ebx,esi         ;edi=p21x*p31y
                pop     edi

                sub     ecx,ebx
                jns     @@no_add

                cmp     edx,[z_minima]
                jle     @@no_add

;               mov     ebx,edx
;               write

;               mov     ebx,[scale]
;               write

;               mov     ebx,[scale3]
;               write

;               mov     ebx,[log]
;               write

                sub     edx,[scale3]
                add     edx,[radio]

;               mov     ebx,edx
;               write
;               write2


                mov     ecx,[log]
                shr     edx,cl
;               xor     dl,dl                   ; 128 dd * ( 256 * 3 )
                and     dx,1111111000000000b


                cmp     edx,0007FFF0h           ; protejo escritura
                jae     @@no_add

                add     edx,[OFF_bin]
                mov     ebx,[edx]
                cmp     ebx,127
                jae     @@no_add        ; maximo 127 faces por BIN

                inc     dword ptr [edx]
                mov     [edx+4*ebx+4],edi

@@no_add:       add     edi,16
                pop     ecx
                dec     ecx
                jnz     @@next_face

                ret

Pick_faces      ENDP

;
; Dibuja los planos por orden BIN (Environment mapping)
;

Draw_faces      PROC

                mov     ecx,3*256       ; 3*256  BINS
                mov     ebx,[OFF_bin]
                add     ebx,(3*256)*128*4

@@next_bin:     push    ecx

                sub     ebx,128*4
                mov     ecx,[ebx]
                or      ecx,ecx
                jz      @@skip_bin

@@next_face:    push    ecx
                push    ebx

                mov     edx,[ebx+4*ecx]         ; edx=indice del plano

                mov     ebx,[edx]               ; ebx=indice punto1
                mov     bp,[ebx+4]              ; bp=u1,v1
                shl     ebp,16
                mov     ax,[ebx]                ; ax=x1
                mov     bp,[ebx+2]              ; bp=y1

                mov     ecx,[edx+4]             ; ecx=indice punto2
                mov     di,[ecx+4]              ; di=u2,v2
                shl     edi,16
                mov     bx,[ecx]                ; bx=x2
                mov     di,[ecx+2]              ; di=y2

                mov     edx,[edx+8]             ; edx=indice punto3
                mov     si,[edx+4]              ; si=u3,v3
                shl     esi,16
                mov     cx,[edx]                ; cx=x3
                mov     si,[edx+2]              ; si=y3

                call    phong_fill

                pop     ebx
                pop     ecx
                dec     ecx
                jnz     @@next_face
                mov     [ebx],ecx       ; ecx ğ 0
@@skip_bin:
                pop     ecx
                dec     ecx
                jnz     @@next_bin
                ret

Draw_faces      ENDP


;##################
;back
;##################

loadTGA         PROC
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se abre el fichero TGA³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ax,3d00h
                mov     edx,OFFSET TGA_name
                int     21h
                jc      @@error_load
                mov     [TGA_handle],ax
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se lee la cabecera + paleta (inutil)³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[TGA_handle]
                mov     ecx,(18+768)
                mov     edx,OFFSET Cabecera
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se lee tile de 256*256³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3fh
                mov     bx,[TGA_handle]
                mov     ecx,65536
                mov     edx,[OFF_tga]
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se cierra el fichero TGA³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     ah,3eh
                mov     bx,[TGA_handle]
                int     21h
                jc      @@error_load
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³Se vuelca el tile repetido³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                mov     esi,[OFF_tga]
                mov     edi,[OFF_back]
                mov     edx,200

@@next_line:    mov     ecx,320
                xor     ebx,ebx

@@next_pixel:   and     ebx,000000FFh
                mov     al,[esi+ebx]
                mov     [edi],al
                inc     ebx
                inc     edi
                dec     ecx
                jnz     @@next_pixel

                add     esi,256
                dec     edx
                jnz     @@next_line

                ret

@@error_load:   mov     edx, OFFSET Error2
                mov     ah,9
                int     21h

                ret

loadTGA         ENDP


Start32:
;               call    Debug
;               call    Debug_Run

                mov     ax,13h
                int     10h

                mov     ax,0EE02h
                int     31h
                mov     [BPA],ebx
                mov     eax,0a0000h
                sub     eax,ebx
                mov     [VGA_off],eax

;               call    set_name  (no funciona bajo win xp)
                call    set_name_xp
                call    load3d
                call    loadTGA
                call    SetPaleta
                call    auto_scale

keypressed:
                mov     eax,[xinc]
                mov     ebx,[yinc]
                add     [xan],eax
                add     [yan],ebx

                and     [xan],0FFFh
                and     [yan],0FFFh

                call    Set_verts
                call    Pick_faces
                call    Draw_faces

                call    clearVGA

                cmp     [salto],0
                jz      @@estacional

                mov     eax,[salto]            ;esto en la epoca del DOS hacia
                imul    eax,15                 ;que la figura se elevara poco
                shr     eax,4                  ;desde abajo hasta una posición
                mov     [salto],eax            ;centrada en la pantalla
                add     eax,100                ;pero con la velocidad
                mov     [posy],ax              ;del Pentium D esto ya no se ve :)
@@estacional:
                mov     ah,1
                int     16h
                jz      keypressed

                call    Control
                or      eax,eax
                jnz     keypressed

                mov     ax,3
                int     10h

                mov     ah,9
                mov     edx, OFFSET End_Message
                int     21h

                mov   ax,4C00h
                int   21h

END             Start32
