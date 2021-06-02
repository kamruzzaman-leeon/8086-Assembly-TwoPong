stack segment para stack
	db 64 dup (' ')
stack ends

data segment para 'data'
	
	window_width dw 140h 					; hex of 320 (pixels)	,the width of the window
	window_height dw 0c8h					;hex of 200 (pixels)	,the heigth of the window
	window_bounds dw 6 						;check collisions early
	
	time_aux db 0			;variable used when checking if the time has changed
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
	
	ball_original_x1 dw 0A0h 				;110 -> X1 position of the ball on the beginning of a game
	ball_original_y1 dw 64h 				;100 -> Y1 position of the ball on the beginning of a game
	ball_original_x2 dw 0A0h 				;110 -> X2 position of the ball on the beginning of a game
	ball_original_y2 dw 64h 				;100 -> Y2 position of the ball on the beginning of a game
	ball_x1 dw 0A0h							;current x1 position(column) of the ball1
	ball_y1 dw 64h							;current y1 position (line) of the ball1
	ball_x2 dw 0A0h							;current x2 position(column) of the ball2
	ball_y2 dw 64h							;current x2 position(line) of the ball2
	ball_size dw 04h 						;size of ball (width*heigth)
	ball_velocity_x1 dw 04h					;X1(horizontal) velocity of the ball
	ball_velocity_y1 dw 02h					;y1(vertical) velocity of the ball
	ball_velocity_x2 dw 05h					;X2(horizontal) velocity of the ball
	ball_velocity_y2 dw 02h					;y2(vertical) velocity of the ball
	
	
	paddle_left_x dw 0ah					;current X position of the left paddle
	paddle_left_y dw 55h					;current Y position of the left paddle
	player_one_points db 0
	
	paddle_right_x dw 130h					;current X position of the right paddle
	paddle_right_y dw 55h					;current Y position of the left paddle
	player_two_points db 0
	
	paddle_width dw 06h						;default paddle width
	paddle_height dw 25h					;default paddle heigth
	
	paddle_velocity dw 07h					;default paddle velocity
	
data ends

code segment para 'code'
	
	main proc far
		Assume cs:code,ds:data,ss:stack		;assume as code,data and stack segments the respective registers
		push ds								;push to the stack the DS segment
		sub ax,ax							;clean the Ax register
		push ax								;push Ax to the stack
		mov ax,data							;save on the AX register the contents of the data segment
		mov ds,ax							;save on the DS segment the contents of AX
		pop ax								;release the top item from the stack to the AX register
		pop ax								;release the top item from the stack to the AX register
		
			call clear_screen		;set intial video mode configuration
			
			check_time:		;time checking loop
			
				cmp current_scene,00h	
				je show_main_menu
				
				cmp game_active,00h
				je show_game_over
			
				mov ah,2ch						;get the system time
				int 21h							;CH = hour CL = minute DH = second DL = 1/100 seconds
				
				cmp dl,time_aux					;is the current time equal to the previous one(time_aux)?
				je check_time					;if it is the same ,check again
					;if it's differnt,then draw, move, etc.
				
					;if it reaches this point ,it's because the time has passed
				mov time_aux,dl					;if not update time		
				
				call clear_screen				;clear the screen by restarting the video mode
				 
				call move_ball1					;move the ball 1
				
				call draw_ball1					;draw the ball 1
				
				call move_ball2					;move the ball 2
				
				; call draw_ball2
				
				call move_paddles				;move the two paddles (check for pressing of keys)
				
				call draw_paddles				;draw the two paddles with the updated positions
				
				call draw_ui
				
				jmp check_time				;after everything checks time again
				
				show_game_over:
					call draw_game_over_menu
					jmp check_time			;after everything checks time again
					
				show_main_menu:
					call draw_main_menu
					jmp check_time			;after everything checks time again
			ret
	main endp
	;##########
move_ball1 proc near						;process the movement of the ball
	
		mov ax,ball_velocity_x1
		add ball_x1,ax						;move the ball horizontally
		
		;check if the ball has passed the left boundarie(;ball_x1< 0 + window_bounds)
		;if is colliding,restart its position		
		mov ax,window_bounds			
		cmp ball_x1,ax						;ball_X1 is compared with the left boundarie of the screen (0+window_bounds)		
		jl give_point_to_player_two1 		;if is less,go to give_point_to_player_two1
		 
					;       Check if the ball has passed the right boundarie (BALL_X1 > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)
					;		If is colliding, restart its position
		 
		mov ax,window_width					;BALL_X1 is compared with the right boundarie of the screen (BALL_X1 > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_x1,ax
		jg give_point_to_player_one1		;if is greater, give one point to the player one and reset ball position
		jmp move_Ball_vertically1		
		
		give_point_to_player_one1:			;give one point to the player one and reset ball position
			inc player_one_points			;increment player one points
			call reset_ball_position1 		;reset ball position to the center of the screen
			
			call update_text_p1_points		;update the text of the player two points
			
			cmp player_one_points,05h		;check if this player has reached 5 points
			jge game_overs					;if this player points is 5 or more, the game is over
			ret
			
		give_point_to_player_two1:			;give one point to the player two and reset ball position
			inc player_two_points			;increment player two points
			call reset_ball_position1		;reset ball position to the center of the screen
			
			call update_text_p2_points		;update the text of the player two points
			cmp player_two_points,05h		;check if this player has reached 5 point
			jge game_overs					;if this player points is 5 or more, the game is over
			ret
		
		game_overs:		 					;someone has reached 5 points
			cmp player_one_points,05h		;check wich player has 5 or more points
			jnl winner_is_player_11			;if the player one has not less than 5 points is the winner
			jmp winner_is_player_21			;if not then player two is the winner
			
			winner_is_player_11:
				mov winner_index,01h
				jmp continue_game_over		;update the winner index with the player one index
			winner_is_player_21:
				mov winner_index,02h		;update the winner index with the player two index
				jmp continue_game_over
			
			continue_game_over:
				mov player_one_points,00h		 ;restart player one points
				mov player_two_points,00h		 ;restart player two points
				call update_text_p1_points
				call update_text_p2_points
				mov game_active,00h				 ;stops the game
				ret
		
		move_Ball_vertically1:
			mov ax,ball_velocity_y1		
			add ball_y1,ax						;move the ball vertically
			
			
		; Check if the ball has passed the top boundarie (BALL_Y1 < 0 + WINDOW_BOUNDS)
		;If is colliding, reverse the velocity in Y
		
		mov ax,window_bounds
		cmp ball_y1,ax						 ;BALL_Y1 is compared with the top boundarie of the screen (0 + WINDOW_BOUNDS)
		jl neg_velocity_y1					;if is less reverve the velocity in Y1
		
				;Check if the ball has passed the bottom boundarie (BALL_Y1 > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
				;If is colliding, reverse the velocity in Y1	
				
		mov ax,window_height				
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_y1,ax			;BALL_Y is compared with the bottom boundarie of the screen (BALL_Y1 > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)			
		jg neg_velocity_y1		 ;if is greater reverve the velocity in Y1
		
	; Check if the ball is colliding with the right paddle
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
			
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
		
				;Check if the ball is colliding with the left paddle
		check_collision_left_paddle1:
				; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
				; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH 
				; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		mov ax,ball_x1
		add ax,ball_size
		cmp ax, paddle_left_x
		jng exit_collision_check1 ;if there's no collision exit procedure
		
		mov ax,paddle_left_x
		add ax,paddle_width
		cmp ball_x1,ax
		jnl exit_collision_check1	;if there's no collision exit procedure
		
		mov ax,ball_y1
		add ax,ball_size
		cmp ax,paddle_left_y
		jng exit_collision_check1	;if there's no collision exit procedure
		
		mov ax,paddle_left_y
		add ax,paddle_height
		cmp ball_y1,ax
		jnl exit_collision_check1	;if there's no collision exit procedure
		
		jmp neg_velocity_x1
		
		neg_velocity_y1:
			neg ball_velocity_y1	;ball_velocity_y1 = - ball_velocity_y1
			ret
		neg_velocity_x1:
			neg ball_velocity_x1 	;ball_velocity_x1 = - ball_velocity_x1
			ret
			
		exit_collision_check1:
			ret			
	move_ball1 endp
	
	;####
	reset_ball_position1 proc near ;reset ball 1 position
		
		mov ax,ball_original_x1 	
		mov ball_x1,ax
		
		mov ax,ball_original_y1
		mov ball_y1,ax
		
		neg ball_velocity_x1 	;ball_velocity_x1= - ball_velocity_x1
		neg ball_velocity_y1	;ball_velocity_y1= - ball_velocity_y1
		
	ret
	reset_ball_position1 endp
	
	
	;###############ball2################
	
	
	move_ball2 proc near
	
		mov ax,ball_velocity_x2
		add ball_x2,ax
		
		mov ax,window_bounds
		cmp ball_x2,ax
		jl give_point_to_player_two2
		
		mov ax,window_width
		sub ax,ball_size
		sub ax,window_bounds
		cmp ball_x2,ax
		jg give_point_to_player_one2
		jmp move_Ball_vertically2
		
		give_point_to_player_one2:
			inc player_one_points
			call reset_ball_position2
			
			call update_text_p1_points
			
			cmp player_one_points,05h
			jge game_overs2
			ret
			
		give_point_to_player_two2:
			inc player_two_points
			call reset_ball_position2
			
			call update_text_p2_points
			cmp player_two_points,05h
			jge game_overs2
			ret
		
		game_overs2:
			cmp player_one_points,05h
			jnl winner_is_player_12
			jmp winner_is_player_22
			
			winner_is_player_12:
				mov winner_index,01h
				jmp continue_game_over2
			winner_is_player_22:
				mov winner_index,02h
				jmp continue_game_over2
			
			continue_game_over2:
				mov player_one_points,00h
				mov player_two_points,00h
				call update_text_p1_points
				call update_text_p2_points
				mov game_active,00h
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
		jng check_collision_left_paddle2
		
		mov ax,paddle_right_x
		add ax,paddle_width
		cmp ball_x2,ax
		jnl check_collision_left_paddle2
		
		mov ax,ball_y2
		add ax,ball_size
		cmp ax,paddle_right_y
		jng check_collision_left_paddle2
		
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ball_y2,ax
		jnl check_collision_left_paddle2
		
		jmp neg_velocity_x2
		
		check_collision_left_paddle2:
		
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
		
		mov ax,paddle_left_y
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
		
		neg ball_velocity_x2
		neg ball_velocity_y2
		
		ret
	reset_ball_position2 endp
	
	
	;###############:#################;
	
	move_paddles proc near
		;##left paddle movement
		;check if any key is being pressed (if not exit procedure)
		mov ah,01h  					;keyboard bios services
		int 16h							;wait for keypress and read character
		jz check_right_paddle_movement 	;zero flag ZF=1,jz ->jump if zero
										;check which key is being pressed (al = ascii character)
		mov ah,00h
		int 16h

		cmp al,77h ;###'w' move up
		je move_left_paddle_up 		;jump equal
			
		cmp al,57h ;###'W' move up
		je move_left_paddle_up		;jump equal
		
		cmp al,73h ;###'s' move down
		je move_left_paddle_down	;jump equal
				
		cmp al,53h ;###'S' move down
		je move_left_paddle_down		;jump equal
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
		mov cx,ball_x1		;set the intial column (X)
		mov dx,ball_y1		;set the intial line (Y)
		
		draw_ball_horizontal1:
		mov ah,0ch			;set the configuration to writing a pixel
		mov al,0ch 			;choose red as color
		mov bh,00h			;set the page number
		int 10h				;execute the configuration
		
		inc cx				;cx=cx+1
		mov ax,cx			;ax-ball_X1 > ball_size (Y-> we go the next line,N-> we continue to the next column)
		sub ax,ball_x1		
		cmp ax,ball_size	
		jng draw_ball_horizontal1
		
		mov cx,ball_x1		;the cx register goes back to the initial column
		inc dx				;we advances one line 
		
		mov ax,dx			;dx-Ball_y1 > ball_size(Y-> we go the next procedure,N-> we continue to the next line)
		sub ax,ball_y1
		cmp ax,ball_size
		jng draw_ball_horizontal1
		
		
	draw_ball1 endp
	;######
	draw_ball2 proc near
			;ball2
		mov cx,ball_x2		;set the intial column (X)
		mov dx,ball_y2		;set the intial line (Y)
		
		draw_ball_horizontal2:
		mov ah,0ch			;set the configuration to writing a pixel
		mov al,0ah 			;choose green as color
		mov bh,00h			;set the page number
		int 10h				;execute the configuration
		
		inc cx							;cx=cx+1
		mov ax,cx						;ax-ball_X2 > ball_size (Y-> we go the next line,N-> we continue to the next line)
		sub ax,ball_x2			
		cmp ax,ball_size
		jng draw_ball_horizontal2
		
		mov cx,ball_x2			;the cx register goes back to the initial column
		inc dx					;we advances one line
		
		mov ax,dx				;dx - Ball_y2 > ball_size(Y-> we go the next procedure,N-> we continue to the next line)
		sub ax,ball_y2
		cmp ax,ball_size
		jng draw_ball_horizontal2

		ret
	draw_ball2 endp
	;#################
	
	draw_paddles proc near
	
	
		;<-------left paddle-------->
		mov cx,paddle_left_x		;set the intial column (x)
		mov dx,paddle_left_y		;set the inti line (y)
		
		draw_paddle_left_horizontal:
			mov ah,0ch				;set the configuration to writing a pixel 
			mov al,0fh 				;white paddle left
			mov bh,00h				;set the page number
			int 10h					;execute the configuration
			
			inc cx					;cx =cx+1
			mov ax,cx					;cx - paddle_left_x > paddle_width(Y-> we go to the next line,N-> we continue to the next column)
			sub ax,paddle_left_x
			cmp ax,paddle_width
			jng draw_paddle_left_horizontal
			
			mov cx,paddle_left_x	;the cx register goes back to the initial column
			inc dx					;we advance one line
			
			mov ax,dx				;dx- paddle_left_y > paddle_height(Y-> we exit this procedure,N-> we continue to the next column )
			sub ax,paddle_left_y
			cmp ax,paddle_height
			jng draw_paddle_left_horizontal
		

			;<-------right paddle-------->
		mov cx,paddle_right_x			;set the intial column (x)
		mov dx,paddle_right_y			;set the inti line (y)
		
		draw_paddle_right_horizontal:
			mov ah,0ch					;set the configuration to writing a pixel
			mov al,0fh 					;white paddle right
			mov bh,00h					;set the page number
			int 10h						;execute the configuration
			
			inc cx						;cx =cx+1
			mov ax,cx					;cx - paddle_right_x > paddle_width(Y-> we go to the next line,N-> we continue to the next column)
			sub ax,paddle_right_x
			cmp ax,paddle_width
			jng draw_paddle_right_horizontal
			
			mov cx,paddle_right_x		;the cx register goes back to the initial column
			inc dx						;we advance one line
			
			mov ax,dx 
			sub ax,paddle_right_y		;dx- paddle_right_y > paddle_height(Y-> we exit this procedure,N-> we continue to the next column) )
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
		
		mov ah,09h				;WRITE STRING TO STANDARD OUTPUT
		lea dx,text_p2_points	;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		int 21h					;print the string 
		
		ret
	draw_ui endp
	
	update_text_p1_points proc near
	
		xor ax,ax
		mov al,player_one_points 	;given, for example that P1 -> 2 points => AL,2
		
		;now, before printing to the screen, we need to convert the decimal value to the ascii code character 
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		
		add al,30h		;AL,'2'
		mov [text_p1_points],al
		 
		ret
	update_text_p1_points endp
	
	update_text_p2_points proc near
		xor ax,ax
		mov al,player_two_points     ;given, for example that P2 -> 2 points => AL,2
		
		;now, before printing to the screen, we need to convert the decimal value to the ascii code character 
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		
		add al,30h		;AL,'2'
		mov [text_p2_points],al
	
		ret
	update_text_p2_points endp
	
	draw_game_over_menu proc near   ;draw the game over menu
		
		call clear_screen			;clear the screen before displaying the menu
		
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
		
		mov ah,09h							;WRITE STRING TO STANDARD OUTPUT
		lea dx,text_play_again				;give DX a pointer
		int 21h								;print the string
		;main menu
		mov ah,02h  ;cursor position
		mov bh,00h	;page number
		mov dh,0Ah  ;row
		mov dl,04h  ;column
		int 10h
		
		mov ah,09h							;WRITE STRING TO STANDARD OUTPUT
		lea dx,text_game_over_menu			;give DX a pointer
		int 21h								;print the string
		
		
		mov ah,00h
		int 16h
		
		cmp al ,'R'				;replay
		je restart_game
		cmp al, 'r'
		je restart_game
		cmp al ,'E'				;exit to main menu
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
		
		mov ah,09h						;WRITE STRING TO STANDARD OUTPUT
		lea dx,text_main_menu_title     ;give DX a pointer
		int 21h							;print the string
		
		; mov ah,02h  ;cursor position
		; mov bh,00h	;page number
		; mov dh,06h  ;row
		; mov dl,04h  ;column
		; int 10h
		
		; mov ah,09h
		; lea dx,text_main_menu_singleplayer
		; int 21h
		
		; mov ah,02h  ;cursor position
		; mov bh,00h	;page number
		; mov dh,08h  ;row
		; mov dl,04h  ;column
		; int 10h
		
		; mov ah,09h
		; lea dx,text_main_menu_multiplayer
		; int 21h
		
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
		cmp al ,'E'		;exit to main menu
		je exit
		cmp al, 'e'
		je exit
		 
		exit:
			mov ah,4ch   ;terminate program
			int 21h
			
	draw_main_menu endp
	
	update_winner_text proc near
		mov al,winner_index					 ;if winner index is 1 => AL,1
		add al,30h							 ;AL,31h => AL,'1'
		mov [text_game_over_winner+7],al  	 ;update the index in the text with the character
		ret
	update_winner_text endp
	
	clear_screen proc near	;clear the screen by restarting the video mode
		mov ah,00h		;set the configuration to video mode
		mov al,13h		;choose the video mode
		int 10h			;execute the configuration
		
		MOV AH, 0Bh     ;set the configuration
		MOV BH, 00h		;to the background color
		MOV BL, 00H     ;choose black as background color
		INT 10h			;execute the configuration
		
		ret
	clear_screen endp
	
code ends
end		
	