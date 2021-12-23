// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
#include <time.h>
#include "aes.h"

#include "firmware.h"
#include "stdio.h"
#define STAT_ADDR 0x21000000

#define START_SIG 0x01
#define STOP_SIG 0x00
#define TIMEOUT 1000
#define CT_Print 0
#define PT_Print 1
#define Bit128 0x01
#define Bit192 0x02
#define Bit256 0x03
#define DisableKey 0x00

#define BASE 0x25000000
#define KEY_BASE (BASE + 4)

#define PT_ENCR_BASE (BASE + 36)
#define PT_VALID_IN (BASE + 52)
#define CT_DECR_BASE (BASE + 56)
#define CT_VALID_IN (BASE + 72)

#define CT_RDY (BASE)
#define CT_ENCR_BASE (BASE+4)
#define PT_RDY (BASE + 20)
#define PT_DECR_BASE (BASE + 24)

#define RESET_ADDR (BASE + 76)
#define KEY_INPUT_STATUS (BASE + 40)
#define PT_IN_RDY (BASE + 52)
#define CT_IN_RDY (BASE + 56)

void accel_hello(void);
void send_stat(bool status);
void Writeword(int x, int addr);
int Readword(int addr);
void Write_short_key(int short_key0, int short_key1, int short_key2, int short_key3, int short_key4, int short_key5, int short_key6, int short_key7, int key_len);
void Write_PT_Encr(int pt_encr0, int pt_encr1, int pt_encr2, int pt_encr3);
void Write_CT_Decr(int ct_decr0, int ct_decr1, int ct_decr2, int ct_decr3);
void RESET_AES(void);
void ChecknWait (int addr);
void Print_AES_Output(bool ct_pt);

void send_stat(bool status)
{
	if (status) {
		*((volatile int *)STAT_ADDR) = 1;
	} else {
		*((volatile int *)STAT_ADDR) = 0;
	}
}

inline void Writeword(int x, int addr) {
	*((volatile int *)addr) = x;
}

inline int Readword(int addr) {
	volatile int *p = (int *)addr;
	return (*p);
}

void Write_short_key(int short_key0, int short_key1, int short_key2, int short_key3, int short_key4, int short_key5, int short_key6, int short_key7, int key_len) {
	ChecknWait(KEY_INPUT_STATUS);
	//short key
	*((volatile int *)(KEY_BASE))    = short_key0;
	*((volatile int *)(KEY_BASE+4))  = short_key1;
	*((volatile int *)(KEY_BASE+8))  = short_key2;
	*((volatile int *)(KEY_BASE+12)) = short_key3;
	*((volatile int *)(KEY_BASE+16)) = short_key4;
	*((volatile int *)(KEY_BASE+20)) = short_key5;
	*((volatile int *)(KEY_BASE+24)) = short_key6;
	*((volatile int *)(KEY_BASE+28)) = short_key7;

	//key_len
	*((volatile int *)BASE) = key_len;
	*((volatile int *)BASE) = DisableKey;
}

void Write_PT_Encr(int pt_encr0, int pt_encr1, int pt_encr2, int pt_encr3){
	ChecknWait(PT_IN_RDY);

	*((volatile int *)(PT_ENCR_BASE))    = pt_encr0;
	*((volatile int *)(PT_ENCR_BASE+4))  = pt_encr1;
	*((volatile int *)(PT_ENCR_BASE+8))  = pt_encr2;
	*((volatile int *)(PT_ENCR_BASE+12)) = pt_encr3;

	//pt_valid
	*((volatile int *)PT_VALID_IN) = START_SIG;
	*((volatile int *)PT_VALID_IN) = STOP_SIG;
}

void Write_CT_Decr(int ct_decr0, int ct_decr1, int ct_decr2, int ct_decr3) {
	ChecknWait(CT_IN_RDY);

	*((volatile int *)(CT_DECR_BASE))    = ct_decr0;
	*((volatile int *)(CT_DECR_BASE+4))  = ct_decr1;
	*((volatile int *)(CT_DECR_BASE+8))  = ct_decr2;
	*((volatile int *)(CT_DECR_BASE+12)) = ct_decr3;

	//ct_valid
	*((volatile int *)CT_VALID_IN) = START_SIG;
	*((volatile int *)CT_VALID_IN) = STOP_SIG;
}

void ChecknWait (int addr) {   //Timeout can be added here
	volatile int * flag = (int *)addr;
	while ((*flag) == 0) print_str("Waiting..\n");
}

void Print_AES_Output(bool ct_pt) {
	if (ct_pt == CT_Print) {
		print_str("Ciphertext: ");
		print_hex(*((volatile int *)(CT_ENCR_BASE)),    8);
		print_hex(*((volatile int *)(CT_ENCR_BASE+4)),  8);
		print_hex(*((volatile int *)(CT_ENCR_BASE+8)),  8);
		print_hex(*((volatile int *)(CT_ENCR_BASE+12)), 8);
	}
	else {
		print_str("Plaintext: ");
		print_hex(*((volatile int *)(PT_DECR_BASE)),    8);
		print_hex(*((volatile int *)(PT_DECR_BASE+4)),  8);
		print_hex(*((volatile int *)(PT_DECR_BASE+8)),  8);
		print_hex(*((volatile int *)(PT_DECR_BASE+12)), 8);
	}
	print_str("\n");
}

void RESET_AES(void) {
	*((volatile int *)RESET_ADDR) = 1;
	*((volatile int *)RESET_ADDR) = 0;
}

//////////////////////////////////////////////////////////////////////////////
// Sample main program                                                      //
//////////////////////////////////////////////////////////////////////////////

////
// Helper for statistics
int get_num_cycles(void);
int get_num_instr(void);
static void stats_print_dec(unsigned int val, int digits, bool zero_pad);

int get_num_cycles(void)
{
	unsigned int num_cycles;
	__asm__ volatile ("rdcycle %0;" : "=r"(num_cycles));
	return num_cycles;
}

int get_num_instr(void)
{
	unsigned int num_instr;
	__asm__ volatile ("rdinstret %0;" : "=r"(num_instr));
	return num_instr;
}

static void stats_print_dec(unsigned int val, int digits, bool zero_pad) {
	char buffer[32];
	char *p = buffer;
	while (val || digits > 0) {
		if (val)
			*(p++) = '0' + val % 10;
		else
			*(p++) = zero_pad ? '0' : ' ';
		val = val / 10;
		digits--;
	}
	while (p != buffer) {
		if (p[-1] == ' ' && p[-2] == ' ') p[-1] = '.';
		print_chr(*(--p));
	}
}

#define STATS(x) numInstr = get_num_instr(); \
    numCycles = get_num_cycles(); \
    x; \
    numInstr = get_num_instr() - numInstr; \
    numCycles = get_num_cycles() - numCycles; \
    print_str("# Instr:"); \
    print_dec(numInstr); \
    print_str("\n"); \
    print_str("# Cycles:"); \
    print_dec(numCycles); \
    print_str("\n");

void accel_hello(void)
{
	int key_len;
	int short_key0, short_key1, short_key2, short_key3, short_key4, short_key5, short_key6, short_key7;
	int pt_encr0, pt_encr1, pt_encr2, pt_encr3;
    int ct_decr0, ct_decr1, ct_decr2, ct_decr3;
    unsigned int cycle_count, instruc_count;
    
    key_len = Bit128;
    
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

	ct_decr0 = 0x3925841D;
	ct_decr1 = 0x02DC09FB;
	ct_decr2 = 0xDC118597;
	ct_decr3 = 0x196A0B32;

    
    RESET_AES();
    
    cycle_count = get_num_cycles();
    instruc_count = get_num_instr();

    cycle_count = get_num_cycles();
    instruc_count = get_num_instr();
    Write_short_key(short_key0, short_key1, short_key2, short_key3, short_key4, short_key5,                      short_key6, short_key7, key_len);
    Write_PT_Encr(pt_encr0, pt_encr1, pt_encr2, pt_encr3);

    ChecknWait(CT_RDY);
    print_str("Number of cycles taken ");
    print_dec(get_num_cycles() - cycle_count);
    print_str("\nNumber of instrucs taken ");
    print_dec(get_num_instr() - instruc_count);	
    print_str("\nCPI = ");
    stats_print_dec(((100 * (get_num_cycles() - cycle_count)) / (get_num_instr() - instruc_count)) % 100, 2, true);
    print_str("\n");

    Print_AES_Output(CT_Print);
    
    cycle_count = get_num_cycles();
    instruc_count = get_num_instr();
    Write_short_key(short_key0, short_key1, short_key2, short_key3, short_key4, short_key5, short_key6, short_key7, key_len);
    Write_CT_Decr(ct_decr0, ct_decr1, ct_decr2, ct_decr3);
    ChecknWait(PT_RDY);
    print_str("Number of cycles taken ");
    print_dec(get_num_cycles() - cycle_count);
    print_str("\nNumber of instrucs taken ");
    print_dec(get_num_instr() - instruc_count);	
    print_str("\nCPI = ");
    stats_print_dec(((100 * (get_num_cycles() - cycle_count)) / (get_num_instr() - instruc_count)) % 100, 2, true);
    print_str("\n");

    Print_AES_Output(PT_Print);

}


void hello(void)
{
    struct byte key[16];
    key[0].b = 0x2b;
    key[1].b = 0x7e;
    key[2].b = 0x15;
    key[3].b = 0x16;
    key[4].b = 0x28;
    key[5].b = 0xae;
    key[6].b = 0xd2;
    key[7].b = 0xa6;
    key[8].b = 0xab;
    key[9].b = 0xf7;
    key[10].b = 0x15;
    key[11].b = 0x88;
    key[12].b = 0x09;
    key[13].b = 0xcf;
    key[14].b = 0x4f;
    key[15].b = 0x3c;
        
    struct byte state[4][4];
    state[0][0].b = 0x32;
    state[0][1].b = 0x43;
    state[0][2].b = 0xf6;
    state[0][3].b = 0xa8;
    state[1][0].b = 0x88;
    state[1][1].b = 0x5a;
    state[1][2].b = 0x30;
    state[1][3].b = 0x8d;
    state[2][0].b = 0x31;
    state[2][1].b = 0x31;
    state[2][2].b = 0x98;
    state[2][3].b = 0xa2;
    state[3][0].b = 0xe0;
    state[3][1].b = 0x37;
    state[3][2].b = 0x07;
    state[3][3].b = 0x34;
    
    struct byte RoundKey[176];
    print_str("Now in software...\n");
    unsigned int numInstr = 0, numCycles = 0;
    
    print_str("Expanding key...\n");
    
    STATS(KeyExpansion(RoundKey, key));
        
    print_str("Encrypting...\n");
    STATS(Cipher(state, RoundKey));
    
    print_str("Result:\n");
    for (int a = 0; a < 4; a++){
        for (int b = 0; b < 4; b++){
            print_hex(state[b][a].b, 2);
            print_str(" ");
        }
        print_str("\n");
    }
	print_str("\n");
    
    print_str("Decrypting...\n");
    
    STATS(InvCipher(state, RoundKey));
    
    print_str("Result:\n");
    for (int a = 0; a < 4; a++){
        for (int b = 0; b < 4; b++){
            print_hex(state[b][a].b, 2);
            print_str(" ");
        }
        print_str("\n");
    }
	print_str("\n");
    print_str("Now in hardware...\n");
    accel_hello();
    print_str("------------------------\n");
    print_str("Total time for both:\n");
    send_stat(true);
}