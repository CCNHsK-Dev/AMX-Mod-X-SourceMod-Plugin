
/*���o ���a �n�J���A */
native szkp80_login(id)

/*���} szkp80��� */
native szkp80_menu(id)

/*���o �@�뵥�� ���̰����� */
native szkp80_max_lv()

/*���o ���a �@�뵥�� ������ */
native szkp80_get_level(id)

/*���o ���a �@�뵥�� ���g�� */
native szkp80_get_exp(id)

/*���o ���a �@�뵥�� ���ɯŸg�� */
native szkp80_get_uplv_exp(id)

/*���o �S�ص��� ���̰����� */
native szkp80_max_salv()

/*���o ���a �S�ص��� ������ */
native szkp80_get_salevel(id)

/*���o ���a �S�ص��� ���g�� */
native szkp80_get_saexp(id)

/*���o ���a �S�ص��� ���ɯŸg�� */
native szkp80_get_uplv_saexp(id)

/*���o ���a �l�u�] �ƥ� */
native szkp80_get_ammo(id)

/*���o ���a �ݩ��I �I�� */
native szkp80_get_points(id)  

/* ���o ���a �����O ���� */
native szkp80_get_dmglv(id)

/* ���o ���a ���u�t�� ���� */
native szkp80_get_reloadlv(id)

/* ���o ���a ���C��y�O ���� */
native szkp80_get_punchanglelv(id)

/* ���o ���a �@�� ���� */
native szkp80_get_armorlv(id)


/*
 	�H�U�� �_���� ��� ����
*/

/* ���o ��� ���� */
native zps_ass_level(id)

/* ���o �_���� ���� */
native zps_nem_level(id)

/* �H�W2�ӥΪk:
	if (zps_ass_level(id) == 3)    // if ��� ���� = 3
	if (zps_nem_level(id) == 1)    // if �_���� ���� = 3

	���  ���� = 0 or 1 or 2 or 3
	�_���̵��� = 0 or 1 or 2
*/

/* ���o �O�_ ���1�Ŧ^�X */
native zps_round_asslv1()

/* ���o �O�_ ���2�Ŧ^�X */
native zps_round_asslv2()

/* ���o �O�_ ���3�Ŧ^�X */
native zps_round_asslv3()

/* ���o �O�_ �_����1�Ŧ^�X */
native zps_round_nemlv1()

/* ���o �O�_ �_����2�Ŧ^�X */
native zps_round_nemlv2()

/* �H�W5�ӥγ~:�D�n�P�_ �������� */

native zps_assinfected()
native zps_assinfarmor()

native zps_nem_die()
native zps_ass_die()

native zps_spawn_nemass(id)