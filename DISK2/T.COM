æ P      dflts: 103 if paging=pglen;104 clear=1;105=dk buf #K; 106=pg ln;107=width;108=expand tabs?;109=scrn clr codes. T.ASM 01/31/82 Omit operand for help
$!  9":
1:
	� :] � ͭ	T command usage:
T name		type 1 or more files
T name #	count bytes/lines, no print
T name nn	start at line nn
T name label	start at label
T name [P	page the output (or [C to clr scrn too)
T name [Pnn	page the output, nn lines/screen
T name [N	number the output
T name nn[N	start at line nn, number output

[Bnn option sets disk buff to nn K
label	Must match exactly and completely
	To match leading chars, end the string with *:
		T b:foo.asm tr*
$�{
^S suspends, ^X skips file, ^C cancels
 �D:2�21:
��ڳ	��     � D͈��      � R͈�    1� �͈!  "�	:��2�	\ � <ʳ	!] h ͈!e q ͈:��N!�	~6 ����{

=================> XXXXXXXX.XXX
 !<
���!�	͓�����������	°:�>	ʻ6 #x=�¢�|� һ6^�@#w#�|6 #w���!�	͓����>��:�	�#�w*�	|��e+"�	!���w*�	|��ͭ	++STARTINE LINE # TOO HIGH++$:�	� ���#�Aͭ	++STRING NOT FOUND++$�{       Lines,         Bytes
 ��:�	� ʖ!�	<
� ʐ�:ʐ�#�s~�?ʖ�w~� �w> 2�	:�	�ʳ�{    1:	 !�� !<
:�	���~� �����#��!<
��~#���    x��� ���{
 ů�����  � �������^~� � x� �#͋�>�/����~#��s� ������� ��������� ������h���� ����ʳ	�7ȷ�
͋�w�^͋#~��|��~#x��^#V#N#Fx���#~�G#�~#fo�>��>������ �������� �������}ƀo|� g�©�+~+w+++Ó#~�g}�o|�g~���
���+p+q��!X������!I�
~�0<w�:�60+���/��Ɛ'�@'_���� ����m � ��4Ҷ�[�o!m �	> ~�[�o#� �]�� �[�r� ȷ��-�c�N�;�P�I�B���Tʩ�W��C��2�I:��2�y�|�ʿ+"�	� ��[�y���}��y: ����}2�yͭ	++BUFFER SIZE TOO BIG ++$�}��y2�y!  � ȷ��[��4��0DM))	)�o�$��0��:?�2�	:�2�y�}��Z22�y:2�y���Nʄ�P�}�C���2�y�2�y�2�	�y���� ���{�
�:��G:<2���2���� ��������ʳ	�ʭ:���!	~���_͋#������������ � ����2h 2| :�	��7	>2�	!\ �	 ͈:\ 2�	!�	\  ͈���\ � ����k	!�	\  ͈���\ � ���!�	\  ͈���\ � ���<7�=������Ɓo& ��	 ͈�]  ͈�2h � �{�
�:��G:<2���2�	� � � *:
��<   \                                                         