>�8D       COM as of 09/19/81; Type D H  for HELP

$�	� !  9"�1�!] �YADD        � �W�y�n�c�!m  �J>���!] ͊DEL        � �W³�n���r++Name not in table++$!] ��SET        � �W��>2}>�2�͵!] ��CU         � �W�] �           � �J>2!�~#<�w!] �.H          � �W��rD.COM by Ward Christensen.  Help:

fn, ft are specific, afn aft may be ambiguous (? and * allowed)

D SET		sets all filenames on disk into D.COM
D		shows added/erased files since D SET was done
D ADD fn.ft	adds a file to D.COM ("registers" it)
D DEL afn.aft	deletes a file from D.COM ("unregisters" it)
D CU 		to Clean Up by selectively adding, erasing,
		or deleting files.
D afn.aft	5-up directory list (e.g. D *.* or D *.ASM)
		(avoid fn of SET, ADD, DEL, CU)
$:] � 2~�%͵:\ ��3=_� :G�B:G�\ � <�'=�o& )))))� �:}��,:~��!����~<ʚ ���#�|��~��w���@	�o������:�����	�� ������� �����h���x�_�E���A���N��@ (E)rase, (A)dd, or (N)o: $�~#���+�w#� �J���@�>|��=��@�h�<:}���:~���:\ ���!�:O~�������:�ʰ���	�� ������� �����h���x�_�N�C�D�U�!���w#�w�>2}�C (D)elete or (N)o: $>|��=��C�h�?<�� �C:+��<2+���	� ������>.�=�����> �=��~�#��� �=�
----> NOT FOUND:
$ �c� �J>���@���_� ����~�#x��J���#x��W�!�~#<�f+�!�~���!�~6 ��m �?ʎ�#ß#�q�!���w#<¥!�4��q!] >?w#¼�!]  �J���\ � ������\ � ����2}22+�cD ���� ������\ � �����{!� �z������� � ������\ � ���<ʡ!]  �J!] ���r updated and written back to disk$�r++WRITE ERROR, program clobbered++$�r++BAD CLOSE, D.COM CLOBBERED!!++$:���:}����x�h!�~<��=�w#��"�#~#��:�A�3�]  �J�2h ���\ � ���������	)� ����� erased
$ ��*�T]# ~#��^�A�R	�C�J>�2}�@:}����x>�=>
�=�	� *���    j
TE ERROR, program clobbered++$�r++BAD CLOSE, D.COM CLOBBERED!!++$:���:}���FFFFF � ��D       COMHELP    IDXSUMMARY    FUNCTION   HELP2      NEWS       SCANHELP   ENTINTRO   PASSWORD   ENTRHELP   BULLETIN   FIRSTIME   WELCOME    NEXT       MODMHELP   XHELP   COMCBBSOPERDOCCBBSINSTDOCBUILDSUMCOMCBBSTESTCOMCBBSBIO ASMMESSAGE X00LINKASM COMHISTORY 036RESTORE COMFILES1  DOCSYNONYM    HISTORY 361HISTORY 362USERBILDASMUSERBILDCOMXHELP   ASMRESTORE AQMBUILDSUMAQM-CBBSMIS362HELP    QQQ�Q  LP    QQQ  LP    QQQ  LP    QQQ 2  BBSMIS362  BBSMIS362 d, to allow text-processing "hi bit" stuff.

---------	C BBSENT1:
- disallow