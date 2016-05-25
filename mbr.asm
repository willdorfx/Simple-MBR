					        ; SIMPLEST MBR
    [BITS 16]
    ORG 0x00007a00

global _start
_start:
    jmp begin

DISKSIG db 'ZerOS01A'

begin:
    cli                     ; Disable interrupts
    xor cx, cx              ; Set segment registers to zero
    mov es, cx              ;
    mov ds, cx              ;
    mov ss, cx              ;
    mov sp, 0x7A00          ; Stack/Relocation point
    mov di, sp              ; Bottom of relocation point
    mov esi, 0x00007C00     ; MBR original location in memory
    cld                     ;
    mov ch, 1               ; cx = 256reset
    rep movsw               ; Copy self to 0:7A00
    jmp 0:continue          ; JMP to copy of self

continue:
    sti                     ; Enable interrupts
    mov ah, 0x0003          ; Change graphics mode to 80x25
    int 10h                 ;

    mov di, PT1a            ; Partition entries start
    xor cx, cx              ; Counter at 0
findactive:
    mov dh,[di]             ; Get byte at current entry
    cmp dh, 0x80            ; Compare to '80'
    je found                ; If so, jump to 'found'
    cmp cx, 3               ; If not, and on 4th entry
    je ERROR1               ; Jump to 'ERROR1'
    inc cx                  ; Increase counter
    add di, 16              ; Move di to next entry
    jmp findactive          ; Loop

found:
    mov dx, [di]            ; Drive and Head
    add di, 2               ;
    mov cx, [di]            ; Cylinder and Sector
    mov si, 3               ; 3 tries
try:
    mov ax, 0x0201          ; Read one sector
    mov bx, 0x7c00          ; Put at :7c00
    int 13h                 ;
    jnc ok                  ; Jump to 'ok' if success
    dec si                  ; Otherwise, decrease counter
    jnz try                 ; Try again if not zero
    mov esi, errormsg2      ; Out of tries - load 2nd error message
    jmp ERROR               ; Jump to error printing routine

ERROR1:
    mov esi, errormsg1      ; Load 1st error message

ERROR:
    mov ah, 0x0E            ; Teletype output
    mov bx, 0x0007          ; Page 7
disp2:
    lodsb                   ; Load next char
    cmp al, 0x00            ; Compare to null-termination
    je end                  ; If so, end
    int 10h                 ; Display char
    jmp disp2               ; Repeat

end:
    hlt                     ; Stop CPU
    jmp end                 ; Infinte loop

ok:
    jmp 0x7c00              ; execute vbr

errormsg1 db 10,'NO ACTIVE PARTITION!',0
errormsg2 db 10,'ERROR LOADING VBR!',0

 
times (0x1b8 - ($-$$)) nop  ; Padding

 
UID db 0xf5,0xbf,0x0f,0x18  ; Unique Disk ID

BLANK times 2 db 0          ; 0000

PT1a db 0x80,0x20,0x21,0x00 ; Partition 1 entry
PT1b db 0x0C,0x50,0x7F,0x01 ; (Copied from my disk)
PT1c db 0x00,0x08,0x00,0x00 ;
PT1d db 0xb0,0x43,0xF9,0x0D ;
PT2 times 16 db 0           ; Partition 2 entry
PT3 times 16 db 0           ; Partition 3 entry
PT4 times 16 db 0			; Partition 4 entry
 
BOOTSIG dw 0xAA55           ; Boot Signature
