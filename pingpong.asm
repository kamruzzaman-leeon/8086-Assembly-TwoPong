stack segment para stack
	db 64 dup (' ')
stack ends

data segment para 'data'
	
	window_width dw 140h 					; hex (320 pixels)
	window_height dw 0c8h					;hex (200 pixels)
	window_bounds dw 6 						;check collisions early
	
	time_aux db 0
	
	ball_original_x1 dw 0A0h 				;110
	ball_original_y1 dw 64h 				;100
	
	ball_original_x2 dw 0A0h 				;110
	ball_original_y2 dw 64h 				;100
	
	ball_x1 dw 0A0h
	ball_y1 dw 64h
	ball_x2 dw 0A0h
	ball_y2 dw 64h
	
	ball_size dw 04h 						;size of ball (width*heigth)
	
	ball_velocity_x1 dw 03h
	ball_velocity_y1 dw 02h
	
	ball_velocity_x2 dw 04h
	ball_velocity_y2 dw 02h
	
	
	paddle_left_x dw 0ah
	paddle_left_y dw 0ah
	
	paddle_right_x dw 130h
	paddle_right_y dw 0ah
	
	paddle_width dw 05h
	paddle_height dw 1fh
	
	paddle_velocity dw 07h
	
data ends

code segment para 'code'
	
	main proc far
		Assume cs:code,ds:data,ss:stack
		push ds
		sub ax,ax
		push ax
		mov ax,data
		mov ds,ax
		pop ax
		pop ax
		
			call clear_screen
			
			check_time:
			
				mov ah,2ch
				int 21h							;CH = hour CL = minute DH = second DL = 1/100 seconds
				
				cmp dl,time_aux
				je check_time
				
				mov time_aux,dl
				
				call clear_screen
				
				call move_ball1
				
				call move_ball2
				
				call draw_ball
				
				call move_paddles
				
				call draw_paddles
				
				jmp check_time
				
			ret
	main endp
	;##########
move_ball1 proc near
	
		mov ax,ball_velocity_x1
		add ball_x1,ax
		
		mov ax,window_bounds
		cmp ball_x1,ax
		jl reset_position1
		
		mov ax,window_width
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_x1,ax
		jg reset_position1
		jmp move_Ball_vertically1
		
		reset_position1:
			call reset_ball_position1
			ret
		
		move_Ball_vertically1:
			mov ax,ball_velocity_y1
			add ball_y1,ax
			
		mov ax,window_bounds
		cmp ball_y1,ax
		jl neg_velocity_y1
		
		mov ax,window_height
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_y1,ax
		jg neg_velocity_y1
		
		mov ax,ball_x1
		add ax,ball_size
		cmp ax, paddle_right_x
		jng check_collision_left_paddle1
		
		mov ax,paddle_right_x
		add ax,paddle_width
		cmp ball_x1,ax
		jnl check_collision_left_paddle1
		
		mov ax,ball_y1
		add ax,ball_size
		cmp ax,paddle_right_y
		jng check_collision_left_paddle1
		
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ball_y1,ax
		jnl check_collision_left_paddle1
		
		jmp neg_velocity_x1
		
		check_collision_left_paddle1:
		
		mov ax,ball_x1
		add ax,ball_size
		cmp ax, paddle_left_x
		jng exit_collision_check1
		
		mov ax,paddle_left_x
		add ax,paddle_width
		cmp ball_x1,ax
		jnl exit_collision_check1
		
		mov ax,ball_y1
		add ax,ball_size
		cmp ax,paddle_left_y
		jng exit_collision_check1
		
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ball_y1,ax
		jnl exit_collision_check1
		
		jmp neg_velocity_x1
		
		neg_velocity_y1:
			neg ball_velocity_y1
			ret
		neg_velocity_x1:
			neg ball_velocity_x1 
			ret
			
		exit_collision_check1:
			ret	
	move_ball1 endp
	
	;---
	reset_ball_position1 proc near
		
		mov ax,ball_original_x1
		mov ball_x1,ax
		
		mov ax,ball_original_y1
		mov ball_y1,ax
		
	ret
	reset_ball_position1 endp
	
	
	;###############ball2################
	
	
	move_ball2 proc near
	
		mov ax,ball_velocity_x2
		add ball_x2,ax
		
		mov ax,window_bounds
		cmp ball_x2,ax
		jl reset_position2
		
		mov ax,window_width
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_x2,ax
		jg reset_position2
		jmp move_Ball_vertically2
		
		reset_position2:
			call reset_ball_position2
			ret
		
		move_Ball_vertically2:
			mov ax,ball_velocity_y2
			add ball_y2,ax
			
		mov ax,window_bounds
		cmp ball_y2,ax
		jl neg_velocity_y2
		
		mov ax,window_height
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_y2,ax
		jg neg_velocity_y2
		
		mov ax,ball_x2
		add ax,ball_size
		cmp ax, paddle_right_x
		jng check_collision_with_left_paddle2
		
		mov ax,paddle_right_x
		add ax,paddle_width
		cmp ball_x2,ax
		jnl check_collision_with_left_paddle2
		
		mov ax,ball_y2
		add ax,ball_size
		cmp ax,paddle_right_y
		jng check_collision_with_left_paddle2
		
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ball_y2,ax
		jnl check_collision_with_left_paddle2
		
		jmp neg_velocity_x2
		
		check_collision_with_left_paddle2:
		
		mov ax,ball_x2
		add ax,ball_size
		cmp ax, paddle_left_x
		jng exit_collision_check2
		
		mov ax,paddle_left_x
		add ax,paddle_width
		cmp ball_x2,ax
		jnl exit_collision_check2
		
		mov ax,ball_y2
		add ax,ball_size
		cmp ax,paddle_left_y
		jng exit_collision_check2
		
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ball_y2,ax
		jnl exit_collision_check2
		
		jmp neg_velocity_x2
		
		neg_velocity_y2:
			neg ball_velocity_y2
			ret
		neg_velocity_x2:
			neg ball_velocity_x2  
			ret
			
		exit_collision_check2:
			ret	
	move_ball2 endp
	
	
	;========
	reset_ball_position2 proc near
		
		mov ax,ball_original_x2
		mov ball_x2,ax
		
		mov ax,ball_original_y2
		mov ball_y2,ax
		
	ret
	reset_ball_position2 endp
	
	
	;###############:#################;
	
	
	draw_ball proc near
		
		;ball1
		mov cx,ball_x1
		mov dx,ball_y1
		
		draw_ball_horizontal1:
		mov ah,0ch
		mov al,0ch ;red
		mov bh,00h
		int 10h
		
		inc cx
		mov ax,cx
		sub ax,ball_x1
		cmp ax,ball_size
		jng draw_ball_horizontal1
		
		mov cx,ball_x1
		inc dx
		
		mov ax,dx
		sub ax,ball_y1
		cmp ax,ball_size
		jng draw_ball_horizontal1
		
		
		;ball2
		mov cx,ball_x2
		mov dx,ball_y2
		
		draw_ball_horizontal2:
		mov ah,0ch
		mov al,0ah ;green
		mov bh,00h
		int 10h
		
		inc cx
		mov ax,cx
		sub ax,ball_x2
		cmp ax,ball_size
		jng draw_ball_horizontal2
		
		mov cx,ball_x2
		inc dx
		
		mov ax,dx
		sub ax,ball_y2
		cmp ax,ball_size
		jng draw_ball_horizontal2
		
		
		ret
	draw_ball endp
	;#################
	draw_paddles proc near
	
	
		;<-------left paddle-------->
		mov cx,paddle_left_x
		mov dx,paddle_left_y
		
		draw_paddle_left_horizontal:
			mov ah,0ch
			mov al,0fh ;green
			mov bh,00h
			int 10h
			
			inc cx
			mov ax,cx
			sub ax,paddle_left_x
			cmp ax,paddle_width
			jng draw_paddle_left_horizontal
			
			mov cx,paddle_left_x
			inc dx
			
			mov ax,dx
			sub ax,paddle_left_y
			cmp ax,paddle_height
			jng draw_paddle_left_horizontal
		

			;<-------right paddle-------->
		mov cx,paddle_right_x
		mov dx,paddle_right_y
		
		draw_paddle_right_horizontal:
			mov ah,0ch
			mov al,0fh ;green
			mov bh,00h
			int 10h
			
			inc cx
			mov ax,cx
			sub ax,paddle_right_x
			cmp ax,paddle_width
			jng draw_paddle_right_horizontal
			
			mov cx,paddle_right_x
			inc dx
			
			mov ax,dx
			sub ax,paddle_right_y
			cmp ax,paddle_height
			jng draw_paddle_right_horizontal
		
		ret
	draw_paddles endp
	
	move_paddles proc near
	
					;##left paddle movement
		
								;check if any key is being pressed (if not exit procedure)
		mov ah,01h
		int 16h
		jz check_right_paddle_movement
								;check which key is being pressed (al = ascii character)
		
		mov ah,00h
		int 16h
		
		;###'w' move up
		cmp al,77h
		je move_left_paddle_up
		
		;###'W' move up
		cmp al,57h
		je move_left_paddle_up
		
		
		;###'s' move up
		cmp al,73h
		je move_left_paddle_down
		
		;###'S' move up
		cmp al,53h
		je move_left_paddle_down
		jmp check_right_paddle_movement
		
		move_left_paddle_up:
			mov ax,paddle_velocity
			sub paddle_left_y,ax
			
			mov ax,window_bounds
			cmp paddle_left_y,ax
			jl fix_paddle_left_top_position
			jmp check_right_paddle_movement
			
			fix_paddle_left_top_position:
				; mov ax,window_bounds
				mov paddle_left_y,ax
				jmp check_right_paddle_movement
				
		
		move_left_paddle_down:
			mov ax,paddle_velocity
			add paddle_left_y,ax
			mov ax,window_height
			sub ax,window_bounds
			sub ax,paddle_height
			cmp paddle_left_y,ax
			jg fix_paddle_left_bottom_position
			jmp check_right_paddle_movement
			
			fix_paddle_left_bottom_position:
				mov paddle_left_y,ax
				jmp check_right_paddle_movement
			
			

		
		;##Right paddle movement
		check_right_paddle_movement:
		

			;'o'  move up
			CMP AL,6Fh ;
			JE MOVE_RIGHT_PADDLE_UP
			;'O' move up
			CMP AL,4Fh 
			JE MOVE_RIGHT_PADDLE_UP
			
			;'l' move down
			CMP AL,6Ch 
			JE MOVE_RIGHT_PADDLE_DOWN
			
			 ;'L' move down
			CMP AL,4Ch
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
		move_right_paddle_up:
			mov ax,paddle_velocity
			sub paddle_right_y,ax
			
			mov ax,window_bounds
			cmp paddle_right_y,ax
			jl fix_paddle_right_top_position
			jmp exit_paddle_movement
			
			fix_paddle_right_top_position:
				mov ax,window_bounds
				mov paddle_right_y,ax
				jmp exit_paddle_movement
		
		
		;'32' move down
		cmp al,14h
		je move_right_paddle_down
		jmp exit_paddle_movement
		
		
		move_right_paddle_down:
			mov ax,paddle_velocity
			add paddle_right_y,ax
			mov ax,window_height
			sub ax,window_bounds
			sub ax,paddle_height
			cmp paddle_right_y,ax
			jg fix_paddle_right_bottom_position
			jmp exit_paddle_movement
			
			fix_paddle_right_bottom_position:
				mov paddle_right_y,ax
				jmp exit_paddle_movement
		
		
		exit_paddle_movement:
			ret
		
		
		ret
	move_paddles endp
	;##########
	
	clear_screen proc near
		mov ah,00h
		mov al,13h
		int 10h
		
		MOV AH, 0Bh       
		MOV BH, 00h
		MOV BL, 00H       
		INT 10h
		ret
	clear_screen endp
		
code ends
end		
	