ÉUSERBILD as of 09/30/83
Builds an empty CBBS USERS file on the logged in disk
or you may specify a drive: USERBILD B: for example
$!  9"�1�	� :\ 2��� <���File USERS already exists
Type E to erase it:  � �_���E���� ���Aborting ��
The size of the user file is determined by ULEXM,
 (the User Logging Extent Mask)

Input a ULEXM of: 0 to abort

Input a ULEXM of: 1 for a  32K user file of  511 entries.
Input a ULEXM of: 3 for a  64K user file of 1023 entries.
Input a ULEXM of: 7 for a 128K user file of 2047 entries.
Enter the ULEXM value you set or will set in CBBS.ASM:  � ����0��!� �1ʑ!��3ʑ!��7���� <�� ��One . for each sector written:  ���� ��M. � !U�!���+|����� <ʐ��
++ DONE ++$���~<w�:�60+���++ Can't make USERS file on logged-in disk$��
++ Can't write USERS file on logged-in disk
Disk may be full$��
++ Can't close USERS file on logged-in disk$���
 ���~��#~���#�����_� �����	� � � *��� USERS                                , ,                     ,     ,        ,     ,     ,0000G
     , ,                     ,     ,        ,     ,     ,0001G
                                                                                                       