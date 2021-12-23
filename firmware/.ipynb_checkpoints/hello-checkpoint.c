// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"

#define STAT_ADDR 0x21000000

#define START_SIG 0x01
#define TIMEOUT 1000

#define BASE 0x25000000
#define KEY_BASE (BASE + 4)

#define PT_ENCR_BASE (BASE + 36)
#define PT_VALID_ADDR (BASE + 52)
#define CT_DECR_BASE (BASE + 56)
#define CT_VALID_ADDR (BASE + 72)

#define CT_RDY_ADDR (BASE)
#define CT_ENCR_BASE (BASE+4)
#define PT_RDY_ADDR (BASE + 20)
#define PT_DECR_BASE (BASE + 24)

void send_stat(bool status);
void Writeword(int x, int addr);
int Readword(int addr);
void Write_short_key(int short_key0, int short_key1, int short_key2, int short_key3, int short_key4, int short_key5, int short_key6, int short_key7, int key_len);
void Write_PT_Encr(int pt_encr0, int pt_encr1, int pt_encr2, int pt_encr3);
void Write_CT_Decr(int ct_decr0, int ct_decr1, int ct_decr2, int ct_decr3);
//void Read_CT_Encr(int ct_encr []);
//void Read_PT_Decr(int ct_encr []);
void AES_StartandWait(void);

void send_stat(bool status)
{
	if (status) {
		*((volatile int *)STAT_ADDR) = 1;
	} else {
		*((volatile int *)STAT_ADDR) = 0;
	}
}

void Writeword(int x, int addr)
{
	volatile int *p = (int *)addr;
	*p = x;
}

int Readword(int addr)
{
	volatile int *p = (int *)addr;
	return (*p);
}

void Write_short_key(int short_key0, int short_key1, int short_key2, int short_key3, int short_key4, int short_key5, int short_key6, int short_key7, int key_len)
{
	int key_ready = Readword(BASE+40);
	while (key_ready == 0) print_str("Waiting to give key..");
	
    Writeword(short_key0,KEY_BASE);
    Writeword(short_key1,KEY_BASE+4);
    Writeword(short_key2,KEY_BASE+8);
    Writeword(short_key3,KEY_BASE+12);
    Writeword(short_key4,KEY_BASE+16);
    Writeword(short_key5,KEY_BASE+20);
    Writeword(short_key6,KEY_BASE+24);
    Writeword(short_key7,KEY_BASE+28);
    Writeword(key_len, BASE);
}

void Write_PT_Encr(int pt_encr0, int pt_encr1, int pt_encr2, int pt_encr3)
{
	volatile int *pt_valid = (int *)PT_VALID_ADDR;

	Writeword(pt_encr0,PT_ENCR_BASE);
	Writeword(pt_encr1,PT_ENCR_BASE+4);
    Writeword(pt_encr2,PT_ENCR_BASE+8);
    Writeword(pt_encr3,PT_ENCR_BASE+12);
    
	*pt_valid = START_SIG; 
	*pt_valid = 0x00;
}

void Write_CT_Decr(int ct_decr0, int ct_decr1, int ct_decr2, int ct_decr3)
{
	volatile int *ct_valid = (int *)CT_VALID_ADDR;
    
	Writeword(ct_decr0,CT_DECR_BASE);
	Writeword(ct_decr1,CT_DECR_BASE+4);
    Writeword(ct_decr2,CT_DECR_BASE+8);
    Writeword(ct_decr3,CT_DECR_BASE+12);
    
	*ct_valid = START_SIG; 
	*ct_valid = 0x00;
}

/*void Read_CT_Encr(int ct_encr [])
{
	for(i=0; i<4; i++)
	{
		Readword(ct_encr[i],CT_ENCR_BASE+(4*i));
	}
}

void Read_PT_Decr(int pt_decr [])
{
	for(i=0; i<4; i++)
	{
		Readword(pt_decr[i],PT_DECR_BASE+(4*i));
	}
}*/

void AES_StartandWait(void)
{
	//volatile int *pt_valid = (int *)PT_VALID_ADDR
	//volatile int *ct_valid = (int *)CT_VALID_ADDR;
	volatile int *pt_rdy = (int *)PT_RDY_ADDR;
	volatile int *ct_rdy = (int *)CT_RDY_ADDR;

	//*pt_valid = START_SIG; 
	//*pt_valid = 0;
	//*ct_valid = START_SIG; 
	//*ct_valid = 0;

	bool rdy = false;
	int count = 0;
	while (!rdy && (count < TIMEOUT)) {
		volatile int x = (*pt_rdy); 
		volatile int y = (*ct_rdy);
		if (((x|y) & 0x01) == 1) rdy = true;
		count++;
		print_str("Waiting..");
	}
	if (count == TIMEOUT) {
		print_str("TIMED OUT: did not get a 'ready' signal back from AES!");
	}
}

void hello(void)
{
	int key_len;
	int short_key0, short_key1, short_key2, short_key3, short_key4, short_key5, short_key6, short_key7;
	int pt_encr0, pt_encr1, pt_encr2, pt_encr3;
    //int ct_encr0, ct_encr1, ct_encr2, ct_encr3;
	//int pt_decr[4], ct_decr[4];
    
    key_len = 0x00000001;
    
	short_key0 = 0x2b7e1516;
    short_key1 = 0x28aed2a6;
	short_key2 = 0xabf71588;
	short_key3 = 0x09cf4f3c;
    short_key4 = 0x00000000;
    short_key5 = 0x00000000;
	short_key6 = 0x00000000;
	short_key7 = 0x00000000;

    pt_encr0 = 0x3243f6a8;
	pt_encr1 = 0x885a308d;
	pt_encr2 = 0x313198a2;
	pt_encr3 = 0xe0370734;
    
    Writeword(1,BASE + 76);
    Writeword(0,BASE + 76);
	Write_short_key(short_key0, short_key1, short_key2, short_key3, short_key4, short_key5, short_key6, short_key7, key_len);
    Write_PT_Encr(pt_encr0, pt_encr1, pt_encr2, pt_encr3);
	AES_StartandWait();
	
    print_str("\n");
    print_hex(Readword(CT_ENCR_BASE),8);
    print_hex(Readword(CT_ENCR_BASE+4),8);
    print_hex(Readword(CT_ENCR_BASE+8),8);
    print_hex(Readword(CT_ENCR_BASE+12),8);
    print_str("\n");
    send_stat(true);
}

