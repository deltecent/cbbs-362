�4FIND.COM as of 10/01/83 Omit operands for help
$�	� !  9"m1m:] � ����Find.com by Ward Christensen.  Usage:

find filename string

where:
 filename is any name, ? and * allowed.
 string is any ascii string to search for.

Special characters in string:
 ? matches any character
 | means "or" as in "this|that"
 ! means "print subsequent lines" (^X to skip)
 _ means a tab (ex: find b:*.asm _in_|_out_ finds I/O instr.)

^C aborts, ^X skips to next file$� O o& 6 �#~�ʁ� ��#�͓����2����\ � ���<���   0� ;͓!] O ͓!e X ͓�l----> FILE XXXXXXXX.XXX
 !  "�!q x�ʎ��!�͞���w#����
�j�[Ó6#6
���� ���������� �����ʢ������� ���2�!�"o!q�*o��:���7�_��>	#�!�2�?��+��7�|�7N�#��Gy�a��{��_����~��d#~���*o~#�|����$�d>2���l    	 !q~_���� ���~#�
�D�d!>~�0<w�:�60+�^�^���� ���#~��m����++bad string++$~#x��^#V#N#Fx���#~�G#�~#fo>������ �������� �������}ƀo|� g�´�+~+w+++Þ#~�g}�o|�g~���+p+q����� � ����2h 2| :���S>2�!\ � ͓:\ 2�!�\  ͓���\ � ���Ç!�\  ͓���\ � ���!�\  ͓���\ � ���<7�=������Ɓo& �� ͓�]  ͓�2h � #fo>������ ���������
++ABORT++$�	� *m�� r
  
\                      