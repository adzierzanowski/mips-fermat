# 12. Napisz program realizuj¹cy algorytm Fermata dla argumentów podanych przez u¿ytkownika.

.data
info1: .asciiz "Projekt III, temat #12: Algorytm Fermata\n"
info2: .asciiz "Aleksander Dzierzanowski, grupa 4. WZIM SGGW 2015"

msg1: .asciiz "\n\nPodaj liczbe (> 1): "
msg2: .asciiz "Czynniki pierwsze: "
msg3: .asciiz "\nPowtorzyc faktoryzacje dla innej liczby? [t/n]: "

msgerr1: .asciiz "\nBlad: podano liczbe mniejsza lub rowna 1."

separator: .asciiz ", "

.text
main:
	# wyœwietl informacje o programie
	li $v0, 4
	
	la $a0, info1
	syscall

	la $a0, info2
	syscall
	
body:				# g³ówna pêtla programu
	li $v0, 4
	la $a0, msg1
	syscall

	li $v0, 5
	syscall
	
	ble $v0, 1, error1
	
	move $v1, $v0
	
	li $v0, 4
	la $a0, msg2
	syscall
		
	move $a0, $v1
	jal factorize

	j prompt_repeat

error1:
	li $v0, 4
	la $a0, msgerr1
	syscall
	
prompt_repeat:
	li $v0, 4
	la $a0, msg3
	syscall
	
	li $v0, 12
	syscall
	
	li $t0, 't'
	beq $v0, $t0, body

	li $v0, 10
	syscall

factorize:
	# in:  $a0 = liczba, która ma zostaæ poddana faktoryzacji
	# out: czynniki pierwsze liczby $a0
	
	move $s1, $sp						# zachowaj pozycjê stosu
	
	# push $a0
	sub $sp, $sp, 4
	sw $a0, ($sp)

	get_factor:
		# pop $a0
		lw $a0, ($sp)
		add $sp, $sp, 4
		
		beq $a0, 1, factorize_return	# $a0 = 1 => zakoñcz bez wypisania
		beq $a0, 2, factorize_preturn	# $a0 = 2 => zakoñcz z wypisaniem
		
		div $t0, $a0, 2					# $t0 = $a0 / 2
		mfhi $t1						# $t1 = $hi = $a0 % 2
		
		beqz $t1, even
		
		odd:
			move $s0, $ra				# zapisz adres powrotu
			jal fermat					# $v0 = czynnik n
			move $ra, $s0				# przywróæ adres powrotu
		
			beq $v0, 1, odd_print		# je¿eli nie ma ju¿ czego rozk³adaæ
			
			# push $a0 / $v0
			div $a0, $a0, $v0
			sub $sp, $sp, 4
			sw $a0, ($sp)
			
			# push $v0
			sub $sp, $sp, 4
			sw $v0, ($sp)
			
			j get_factor
			
			odd_print:
				beq $sp, $s1, factorize_preturn	# je¿eli stos jest pusty
				
				li $v0, 1
				syscall
				
				li $v0, 4
				la $a0, separator
				syscall
				
				j get_factor
		
		even:	
			li $a0, 2
			li $v0, 1
			syscall
			
			li $v0, 4
			la $a0, separator
			syscall
			
			# push $t0 = $a0 / 2
			sub $sp, $sp, 4
			sw $t0, ($sp)
			
			j get_factor

	factorize_preturn:
		li $v0, 1
		syscall

	factorize_return:
		jr $ra

fermat:
	# in:  $a0 = liczba, która ma zostaæ poddana algorytmowi (powinna byæ nieparzysta)
	# out: $v0 = dzielnik $a0
	
	# sprawdzamy, czy liczba jest kwadratem liczby naturalnej
	mtc1 $a0, $f0			# za³aduj argument do koprocesora
	cvt.s.w $f0, $f0		# int -> float
	sqrt.s $f1, $f0			# $f1 = sqrt($f0)
	
	floor.w.s $f2, $f1		# zostaw czêœæ ca³kowit¹ $f1 w $f2
	mfc1 $t0, $f2			# przenieœ $f2 z koprocesora do $t0
	
	mul $t0, $t0, $t0		# $t0 = ($t0)^2
	bne $t0, $a0, not_a_square
	
	mfc1 $v0, $f2			# return sqrt($a0)
	
	j fermat_return
	
	not_a_square:
		ceil.w.s $f2, $f1
		mfc1 $t0, $f2		# r = $t0 = ceil(sqrt($a0))
		
		mul $t1, $t0, $t0
		sub $t1, $t1, $a0	# e = $t1 = ($t0)^2 - $a0
		
		mul $t2, $t0, 2
		add $t2, $t2, 1		# u = $t2 = 2 * $t0 + 1
		
		li $t3, 1			# v = $t3 = 1
		
		find_factor:
			beqz $t1, found_factor		# if (e == 0)
			bltz $t1, e_less_than_zero	# if (e < 0)
			bgtz $t1, e_more_than_zero	# if (e > 0)
						
			found_factor:
				sub $v0, $t2, $t3
				div $v0, $v0, 2
				j fermat_return			# return (u - v) / 2
			
			e_less_than_zero:
				add $t1, $t1, $t2		# e += u
				add $t2, $t2, 2	# u += 2
				j find_factor
				
			e_more_than_zero:
				sub $t1, $t1, $t3		# e -= v
				add $t3, $t3, 2	# v += 2
				j find_factor
		
	fermat_return:
		jr $ra
