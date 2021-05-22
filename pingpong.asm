stack segment para stack
	db 64 dup (' ')
stack ends

data segment para 'data'
	
	window_width dw 140h 					; hex (320 pixels)
	window_height dw 0c8h					;hex (200 pixels)
	window_bounds dw 6 						;check collisions early
	
	time_aux db 0
	game_active db 1
	winner_index db 0
	current_scene db 1
	
	text_p1_points db '0','$'
	text_p2_points db '0','$'
	text_game_over_title db 'Game over','$'
	text_game_over_winner db 'player 0 won' ,'$'
	text_play_again db 'press R to play again', '$'
	text_game_over_menu db 'press E to exit to main menu','$'
	text_main_menu_title db 'MAIN MENU' ,'$'
	text_main_menu_singleplayer db 'singleplayer - s key ','$'
	text_main_menu_multiplayer db 'multiplayer - m key ','$'
	text_main_menu_exit db 'exit game - E key','$'
	
	ball_original_x1 dw 0A0h 				;110
	ball_original_y1 dw 64h 				;100
	ball_original_x2 dw 0A0h 				;110
	ball_original_y2 dw 64h 				;100
	ball_x1 dw 0A0h
	ball_y1 dw 64h
	ball_x2 dw 0A0h
	ball_y2 dw 64h
	ball_size dw 04h 						;size of ball (width*heigth)
	ball_velocity_x1 dw 04h
	ball_velocity_y1 dw 02h
	ball_velocity_x2 dw 05h
	ball_velocity_y2 dw 02h
	
	
	paddle_left_x dw 0ah
	paddle_left_y dw 55h
	player_one_points db 0
	
	paddle_right_x dw 130h
	paddle_right_y dw 55h
	player_two_points db 0
	
	paddle_width dw 06h
	paddle_height dw 25h
	
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
			
				cmp current_scene,00h
				je show_main_menu
				
				cmp game_active,00h
				je show_game_over
			
				mov ah,2ch
				int 21h							;CH = hour CL = minute DH = second DL = 1/100 seconds
				
				cmp dl,time_aux
				je check_time
				
				mov time_aux,dl
				
				call clear_screen
				
				call move_ball1
				
				call draw_ball1
				
				call move_ball2
				
				call draw_ball2
				
				call move_paddles
				
				call draw_paddles
				
				call draw_ui
				
				jmp check_time
				
				show_game_over:
					call draw_game_over_menu
					jmp check_time
					
				show_main_menu:
					call draw_main_menu
					jmp check_time
			ret
	main endp
	;##########
move_ball1 proc near
	
		mov ax,ball_velocity_x1
		add ball_x1,ax
		
		mov ax,window_bounds
		cmp ball_x1,ax
		jl give_point_to_player_two1
		
		mov ax,window_width
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_x1,ax
		jg give_point_to_player_one1
		jmp move_Ball_vertically1
		
		give_point_to_player_one1:
			inc player_one_points
			call reset_ball_position1
			
			call update_text_p1_points
			
			cmp player_one_points,05h
			jge game_overs
			ret
			
		give_point_to_player_two1:
			inc player_two_points
			call reset_ball_position1
			
			call update_text_p2_points
			cmp player_two_points,05h
			jge game_overs
			ret
		
		game_overs:
			cmp player_one_points,05h
			jnl winner_is_player_1
			jmp winner_is_player_2
			
			winner_is_player_1:
				mov winner_index,01h
				jmp continue_game_over
			winner_is_player_2:
				mov winner_index,02h
				jmp continue_game_over
			
			continue_game_over:
				mov player_one_points,00h
				mov player_two_points,00h
				call update_text_p1_points
				call update_text_p2_points
				mov game_active,00h
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
		
		mov ax,paddle_left_y
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
	
	;####
	reset_ball_position1 proc near
		
		mov ax,ball_original_x1
		mov ball_x1,ax
		
		mov ax,ball_original_y1
		mov ball_y1,ax
		
		neg ball_velocity_x1
		neg ball_velocity_y1
		
	ret
	reset_ball_position1 endp
	
	
	;###############ball2################
	
	
	move_ball2 proc near
	
		; mov ax,ball_velocity_x2
		; add ball_x2,ax
		
		; mov ax,window_bounds
		; cmp ball_x2,ax
		; jl reset_position2
		
		; mov ax,window_width
		; sub ax,ball_size
		; sub ax,window_bounds
		; cmp ball_x2,ax
		; jg reset_position2
		; jmp move_Ball_vertically2
		
		; reset_position2:
			; call reset_ball_position2
			; ret
		
		; move_Ball_vertically2:
			; mov ax,ball_velocity_y2
			; add ball_y2,ax
			
		; mov ax,window_bounds
		; cmp ball_y2,ax
		; jl neg_velocity_y2
		
		; mov ax,window_height
		; sub ax,ball_size
		; sub ax,window_bounds
		; cmp ball_y2,ax
		; jg neg_velocity_y2
		
		; mov ax,ball_x2
		; add ax,ball_size
		; cmp ax, paddle_right_x
		; jng check_collision_with_left_paddle2
		
		; mov ax,paddle_right_x
		; add ax,paddle_width
		; cmp ball_x2,ax
		; jnl check_collision_with_left_paddle2
		
		; mov ax,ball_y2
		; add ax,ball_size
		; cmp ax,paddle_right_y
		; jng check_collision_with_left_paddle2
		
		; mov ax,paddle_right_y
		; add ax,paddle_height
		; cmp ball_y2,ax
		; jnl check_collision_with_left_paddle2
		
		; jmp neg_velocity_x2
		
		; check_collision_with_left_paddle2:
		
		; mov ax,ball_x2
		; add ax,ball_size
		; cmp ax, paddle_left_x
		; jng exit_collision_check2
		
		; mov ax,paddle_left_x
		; add ax,paddle_width
		; cmp ball_x2,ax
		; jnl exit_collision_check2
		
		; mov ax,ball_y2
		; add ax,ball_size
		; cmp ax,paddle_left_y
		; jng exit_collision_check2
		
		; mov ax,paddle_right_y
		; add ax,paddle_height
		; cmp ball_y2,ax
		; jnl exit_collision_check2
		
		; jmp neg_velocity_x2
		
		; neg_velocity_y2:
			; neg ball_velocity_y2
			; ret
		; neg_velocity_x2:
			; neg ball_velocity_x2  
			; ret
			
		; exit_collision_check2:
			; ret	
	move_ball2 endp
	
	
	;========
	reset_ball_position2 proc near
		
		mov ax,ball_original_x2
		mov ball_x2,ax
		
		mov ax,ball_original_y2
		mov ball_y2,ax
		
		neg ball_velocity_x2
		neg ball_velocity_y2
		
		ret
	reset_ball_position2 endp
	
	
	;###############:#################;
	
	move_paddles proc near
		;##left paddle movement
		;check if any key is being pressed (if not exit procedure)
		mov ah,01h
		int 16h
		jz check_right_paddle_movement
								;check which key is being pressed (al = ascii character)
		mov ah,00h
		int 16h

		cmp al,77h ;###'w' move up
		je move_left_paddle_up
			
		cmp al,57h ;###'W' move up
		je move_left_paddle_up
		
		cmp al,73h ;###'s' move down
		je move_left_paddle_down
				
		cmp al,53h ;###'S' move down
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
					; mov ax,window_bounds
					mov paddle_right_y,ax
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
		
	move_paddles endp
	;####
	draw_ball1 proc near
		
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
		
		
	draw_ball1 endp
	;######
	draw_ball2 proc near
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
	draw_ball2 endp
	;#################
	
	draw_paddles proc near
	
	
		;<-------left paddle-------->
		mov cx,paddle_left_x
		mov dx,paddle_left_y
		
		draw_paddle_left_horizontal:
			mov ah,0ch
			mov al,0fh ;white paddle left
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
			mov al,0fh ;white paddle right
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
	
	
	;##########
	draw_ui proc near
		;player one
		
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,04h  ;row
		mov dl,06h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_p1_points
		int 21h
		;player two
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,04h  ;row
		mov dl,1fh  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_p2_points
		int 21h
		
		ret
	draw_ui endp
	
	update_text_p1_points proc near
	
		xor ax,ax
		mov al,player_one_points
		add al,30h
		mov [text_p1_points],al
		 
		ret
	update_text_p1_points endp
	
	update_text_p2_points proc near
		xor ax,ax
		mov al,player_two_points
		add al,30h
		mov [text_p2_points],al
	
		ret
	update_text_p2_points endp
	
	draw_game_over_menu proc near
		
		call clear_screen
		
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,04h  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_game_over_title
		int 21h
		;show the winner
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,06h  ;row
		mov dl,04h  ;column
		int 10h
		
		call update_winner_text
		
		mov ah,09h
		lea dx,text_game_over_winner
		int 21h
		
		;show the play again
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,08h  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_play_again
		int 21h
		;main menu
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,0Ah  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_game_over_menu
		int 21h
		
		
		mov ah,00h
		int 16h
		
		cmp al ,'R'		;replay
		je restart_game
		cmp al, 'r'
		je restart_game
		cmp al ,'E'		;exit to main menu
		je exit_to_game
		cmp al, 'e'
		je exit_to_game
		ret
		
		restart_game:
			mov game_active,01h
			ret
			
		exit_to_game:
			mov game_active,00h
			mov current_scene,00h
			ret
		
	draw_game_over_menu endp
		
	draw_main_menu proc near
		call clear_screen
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,04h  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_main_menu_title
		int 21h
		
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,06h  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_main_menu_singleplayer
		int 21h
		
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,08h  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_main_menu_multiplayer
		int 21h
		
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,0Ah  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h
		lea dx,text_main_menu_exit
		int 21h
		
		mov ah,00h
		int 16h
		ret
	draw_main_menu endp
	
	update_winner_text proc near
		mov al,winner_index
		add al,30h
		mov [text_game_over_winner+7],al
		ret
	update_winner_text endp
	
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
	