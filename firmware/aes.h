/* crypto/aes/aes.h -*- mode:C; c-file-style: "eay" -*- */
/* ====================================================================
 * Copyright (c) 1998-2002 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.openssl.org/)"
 *
 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    openssl-core@openssl.org.
 *
 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit (http://www.openssl.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 */

#ifndef HEADER_AES_H
#define HEADER_AES_H


#define Nk 4        // The number of 32 bit words in a key.
#define Nr 10       // The number of rounds in AES Cipher.
#define Nb 4


struct byte{
    unsigned char b;
};

struct byte sbox(struct byte s);
struct byte revsbox(struct byte s);

struct byte sbox(struct byte s){
    unsigned char subbyte;
switch (s.b){
case (unsigned char) 0: subbyte = 99; break;
case (unsigned char) 1: subbyte = 124; break;
case (unsigned char) 2: subbyte = 119; break;
case (unsigned char) 3: subbyte = 123; break;
case (unsigned char) 4: subbyte = 242; break;
case (unsigned char) 5: subbyte = 107; break;
case (unsigned char) 6: subbyte = 111; break;
case (unsigned char) 7: subbyte = 197; break;
case (unsigned char) 8: subbyte = 48; break;
case (unsigned char) 9: subbyte = 1; break;
case (unsigned char) 10: subbyte = 103; break;
case (unsigned char) 11: subbyte = 43; break;
case (unsigned char) 12: subbyte = 254; break;
case (unsigned char) 13: subbyte = 215; break;
case (unsigned char) 14: subbyte = 171; break;
case (unsigned char) 15: subbyte = 118; break;
case (unsigned char) 16: subbyte = 202; break;
case (unsigned char) 17: subbyte = 130; break;
case (unsigned char) 18: subbyte = 201; break;
case (unsigned char) 19: subbyte = 125; break;
case (unsigned char) 20: subbyte = 250; break;
case (unsigned char) 21: subbyte = 89; break;
case (unsigned char) 22: subbyte = 71; break;
case (unsigned char) 23: subbyte = 240; break;
case (unsigned char) 24: subbyte = 173; break;
case (unsigned char) 25: subbyte = 212; break;
case (unsigned char) 26: subbyte = 162; break;
case (unsigned char) 27: subbyte = 175; break;
case (unsigned char) 28: subbyte = 156; break;
case (unsigned char) 29: subbyte = 164; break;
case (unsigned char) 30: subbyte = 114; break;
case (unsigned char) 31: subbyte = 192; break;
case (unsigned char) 32: subbyte = 183; break;
case (unsigned char) 33: subbyte = 253; break;
case (unsigned char) 34: subbyte = 147; break;
case (unsigned char) 35: subbyte = 38; break;
case (unsigned char) 36: subbyte = 54; break;
case (unsigned char) 37: subbyte = 63; break;
case (unsigned char) 38: subbyte = 247; break;
case (unsigned char) 39: subbyte = 204; break;
case (unsigned char) 40: subbyte = 52; break;
case (unsigned char) 41: subbyte = 165; break;
case (unsigned char) 42: subbyte = 229; break;
case (unsigned char) 43: subbyte = 241; break;
case (unsigned char) 44: subbyte = 113; break;
case (unsigned char) 45: subbyte = 216; break;
case (unsigned char) 46: subbyte = 49; break;
case (unsigned char) 47: subbyte = 21; break;
case (unsigned char) 48: subbyte = 4; break;
case (unsigned char) 49: subbyte = 199; break;
case (unsigned char) 50: subbyte = 35; break;
case (unsigned char) 51: subbyte = 195; break;
case (unsigned char) 52: subbyte = 24; break;
case (unsigned char) 53: subbyte = 150; break;
case (unsigned char) 54: subbyte = 5; break;
case (unsigned char) 55: subbyte = 154; break;
case (unsigned char) 56: subbyte = 7; break;
case (unsigned char) 57: subbyte = 18; break;
case (unsigned char) 58: subbyte = 128; break;
case (unsigned char) 59: subbyte = 226; break;
case (unsigned char) 60: subbyte = 235; break;
case (unsigned char) 61: subbyte = 39; break;
case (unsigned char) 62: subbyte = 178; break;
case (unsigned char) 63: subbyte = 117; break;
case (unsigned char) 64: subbyte = 9; break;
case (unsigned char) 65: subbyte = 131; break;
case (unsigned char) 66: subbyte = 44; break;
case (unsigned char) 67: subbyte = 26; break;
case (unsigned char) 68: subbyte = 27; break;
case (unsigned char) 69: subbyte = 110; break;
case (unsigned char) 70: subbyte = 90; break;
case (unsigned char) 71: subbyte = 160; break;
case (unsigned char) 72: subbyte = 82; break;
case (unsigned char) 73: subbyte = 59; break;
case (unsigned char) 74: subbyte = 214; break;
case (unsigned char) 75: subbyte = 179; break;
case (unsigned char) 76: subbyte = 41; break;
case (unsigned char) 77: subbyte = 227; break;
case (unsigned char) 78: subbyte = 47; break;
case (unsigned char) 79: subbyte = 132; break;
case (unsigned char) 80: subbyte = 83; break;
case (unsigned char) 81: subbyte = 209; break;
case (unsigned char) 82: subbyte = 0; break;
case (unsigned char) 83: subbyte = 237; break;
case (unsigned char) 84: subbyte = 32; break;
case (unsigned char) 85: subbyte = 252; break;
case (unsigned char) 86: subbyte = 177; break;
case (unsigned char) 87: subbyte = 91; break;
case (unsigned char) 88: subbyte = 106; break;
case (unsigned char) 89: subbyte = 203; break;
case (unsigned char) 90: subbyte = 190; break;
case (unsigned char) 91: subbyte = 57; break;
case (unsigned char) 92: subbyte = 74; break;
case (unsigned char) 93: subbyte = 76; break;
case (unsigned char) 94: subbyte = 88; break;
case (unsigned char) 95: subbyte = 207; break;
case (unsigned char) 96: subbyte = 208; break;
case (unsigned char) 97: subbyte = 239; break;
case (unsigned char) 98: subbyte = 170; break;
case (unsigned char) 99: subbyte = 251; break;
case (unsigned char) 100: subbyte = 67; break;
case (unsigned char) 101: subbyte = 77; break;
case (unsigned char) 102: subbyte = 51; break;
case (unsigned char) 103: subbyte = 133; break;
case (unsigned char) 104: subbyte = 69; break;
case (unsigned char) 105: subbyte = 249; break;
case (unsigned char) 106: subbyte = 2; break;
case (unsigned char) 107: subbyte = 127; break;
case (unsigned char) 108: subbyte = 80; break;
case (unsigned char) 109: subbyte = 60; break;
case (unsigned char) 110: subbyte = 159; break;
case (unsigned char) 111: subbyte = 168; break;
case (unsigned char) 112: subbyte = 81; break;
case (unsigned char) 113: subbyte = 163; break;
case (unsigned char) 114: subbyte = 64; break;
case (unsigned char) 115: subbyte = 143; break;
case (unsigned char) 116: subbyte = 146; break;
case (unsigned char) 117: subbyte = 157; break;
case (unsigned char) 118: subbyte = 56; break;
case (unsigned char) 119: subbyte = 245; break;
case (unsigned char) 120: subbyte = 188; break;
case (unsigned char) 121: subbyte = 182; break;
case (unsigned char) 122: subbyte = 218; break;
case (unsigned char) 123: subbyte = 33; break;
case (unsigned char) 124: subbyte = 16; break;
case (unsigned char) 125: subbyte = 255; break;
case (unsigned char) 126: subbyte = 243; break;
case (unsigned char) 127: subbyte = 210; break;
case (unsigned char) 128: subbyte = 205; break;
case (unsigned char) 129: subbyte = 12; break;
case (unsigned char) 130: subbyte = 19; break;
case (unsigned char) 131: subbyte = 236; break;
case (unsigned char) 132: subbyte = 95; break;
case (unsigned char) 133: subbyte = 151; break;
case (unsigned char) 134: subbyte = 68; break;
case (unsigned char) 135: subbyte = 23; break;
case (unsigned char) 136: subbyte = 196; break;
case (unsigned char) 137: subbyte = 167; break;
case (unsigned char) 138: subbyte = 126; break;
case (unsigned char) 139: subbyte = 61; break;
case (unsigned char) 140: subbyte = 100; break;
case (unsigned char) 141: subbyte = 93; break;
case (unsigned char) 142: subbyte = 25; break;
case (unsigned char) 143: subbyte = 115; break;
case (unsigned char) 144: subbyte = 96; break;
case (unsigned char) 145: subbyte = 129; break;
case (unsigned char) 146: subbyte = 79; break;
case (unsigned char) 147: subbyte = 220; break;
case (unsigned char) 148: subbyte = 34; break;
case (unsigned char) 149: subbyte = 42; break;
case (unsigned char) 150: subbyte = 144; break;
case (unsigned char) 151: subbyte = 136; break;
case (unsigned char) 152: subbyte = 70; break;
case (unsigned char) 153: subbyte = 238; break;
case (unsigned char) 154: subbyte = 184; break;
case (unsigned char) 155: subbyte = 20; break;
case (unsigned char) 156: subbyte = 222; break;
case (unsigned char) 157: subbyte = 94; break;
case (unsigned char) 158: subbyte = 11; break;
case (unsigned char) 159: subbyte = 219; break;
case (unsigned char) 160: subbyte = 224; break;
case (unsigned char) 161: subbyte = 50; break;
case (unsigned char) 162: subbyte = 58; break;
case (unsigned char) 163: subbyte = 10; break;
case (unsigned char) 164: subbyte = 73; break;
case (unsigned char) 165: subbyte = 6; break;
case (unsigned char) 166: subbyte = 36; break;
case (unsigned char) 167: subbyte = 92; break;
case (unsigned char) 168: subbyte = 194; break;
case (unsigned char) 169: subbyte = 211; break;
case (unsigned char) 170: subbyte = 172; break;
case (unsigned char) 171: subbyte = 98; break;
case (unsigned char) 172: subbyte = 145; break;
case (unsigned char) 173: subbyte = 149; break;
case (unsigned char) 174: subbyte = 228; break;
case (unsigned char) 175: subbyte = 121; break;
case (unsigned char) 176: subbyte = 231; break;
case (unsigned char) 177: subbyte = 200; break;
case (unsigned char) 178: subbyte = 55; break;
case (unsigned char) 179: subbyte = 109; break;
case (unsigned char) 180: subbyte = 141; break;
case (unsigned char) 181: subbyte = 213; break;
case (unsigned char) 182: subbyte = 78; break;
case (unsigned char) 183: subbyte = 169; break;
case (unsigned char) 184: subbyte = 108; break;
case (unsigned char) 185: subbyte = 86; break;
case (unsigned char) 186: subbyte = 244; break;
case (unsigned char) 187: subbyte = 234; break;
case (unsigned char) 188: subbyte = 101; break;
case (unsigned char) 189: subbyte = 122; break;
case (unsigned char) 190: subbyte = 174; break;
case (unsigned char) 191: subbyte = 8; break;
case (unsigned char) 192: subbyte = 186; break;
case (unsigned char) 193: subbyte = 120; break;
case (unsigned char) 194: subbyte = 37; break;
case (unsigned char) 195: subbyte = 46; break;
case (unsigned char) 196: subbyte = 28; break;
case (unsigned char) 197: subbyte = 166; break;
case (unsigned char) 198: subbyte = 180; break;
case (unsigned char) 199: subbyte = 198; break;
case (unsigned char) 200: subbyte = 232; break;
case (unsigned char) 201: subbyte = 221; break;
case (unsigned char) 202: subbyte = 116; break;
case (unsigned char) 203: subbyte = 31; break;
case (unsigned char) 204: subbyte = 75; break;
case (unsigned char) 205: subbyte = 189; break;
case (unsigned char) 206: subbyte = 139; break;
case (unsigned char) 207: subbyte = 138; break;
case (unsigned char) 208: subbyte = 112; break;
case (unsigned char) 209: subbyte = 62; break;
case (unsigned char) 210: subbyte = 181; break;
case (unsigned char) 211: subbyte = 102; break;
case (unsigned char) 212: subbyte = 72; break;
case (unsigned char) 213: subbyte = 3; break;
case (unsigned char) 214: subbyte = 246; break;
case (unsigned char) 215: subbyte = 14; break;
case (unsigned char) 216: subbyte = 97; break;
case (unsigned char) 217: subbyte = 53; break;
case (unsigned char) 218: subbyte = 87; break;
case (unsigned char) 219: subbyte = 185; break;
case (unsigned char) 220: subbyte = 134; break;
case (unsigned char) 221: subbyte = 193; break;
case (unsigned char) 222: subbyte = 29; break;
case (unsigned char) 223: subbyte = 158; break;
case (unsigned char) 224: subbyte = 225; break;
case (unsigned char) 225: subbyte = 248; break;
case (unsigned char) 226: subbyte = 152; break;
case (unsigned char) 227: subbyte = 17; break;
case (unsigned char) 228: subbyte = 105; break;
case (unsigned char) 229: subbyte = 217; break;
case (unsigned char) 230: subbyte = 142; break;
case (unsigned char) 231: subbyte = 148; break;
case (unsigned char) 232: subbyte = 155; break;
case (unsigned char) 233: subbyte = 30; break;
case (unsigned char) 234: subbyte = 135; break;
case (unsigned char) 235: subbyte = 233; break;
case (unsigned char) 236: subbyte = 206; break;
case (unsigned char) 237: subbyte = 85; break;
case (unsigned char) 238: subbyte = 40; break;
case (unsigned char) 239: subbyte = 223; break;
case (unsigned char) 240: subbyte = 140; break;
case (unsigned char) 241: subbyte = 161; break;
case (unsigned char) 242: subbyte = 137; break;
case (unsigned char) 243: subbyte = 13; break;
case (unsigned char) 244: subbyte = 191; break;
case (unsigned char) 245: subbyte = 230; break;
case (unsigned char) 246: subbyte = 66; break;
case (unsigned char) 247: subbyte = 104; break;
case (unsigned char) 248: subbyte = 65; break;
case (unsigned char) 249: subbyte = 153; break;
case (unsigned char) 250: subbyte = 45; break;
case (unsigned char) 251: subbyte = 15; break;
case (unsigned char) 252: subbyte = 176; break;
case (unsigned char) 253: subbyte = 84; break;
case (unsigned char) 254: subbyte = 187; break;
case (unsigned char) 255: subbyte = 22; break;
}
struct byte result;
result.b = subbyte;
return result;
}

struct byte revsbox(struct byte s){
    unsigned char subbyte;
switch (s.b){
case (unsigned char) 0: subbyte = 82; break;
case (unsigned char) 1: subbyte = 9; break;
case (unsigned char) 2: subbyte = 106; break;
case (unsigned char) 3: subbyte = 213; break;
case (unsigned char) 4: subbyte = 48; break;
case (unsigned char) 5: subbyte = 54; break;
case (unsigned char) 6: subbyte = 165; break;
case (unsigned char) 7: subbyte = 56; break;
case (unsigned char) 8: subbyte = 191; break;
case (unsigned char) 9: subbyte = 64; break;
case (unsigned char) 10: subbyte = 163; break;
case (unsigned char) 11: subbyte = 158; break;
case (unsigned char) 12: subbyte = 129; break;
case (unsigned char) 13: subbyte = 243; break;
case (unsigned char) 14: subbyte = 215; break;
case (unsigned char) 15: subbyte = 251; break;
case (unsigned char) 16: subbyte = 124; break;
case (unsigned char) 17: subbyte = 227; break;
case (unsigned char) 18: subbyte = 57; break;
case (unsigned char) 19: subbyte = 130; break;
case (unsigned char) 20: subbyte = 155; break;
case (unsigned char) 21: subbyte = 47; break;
case (unsigned char) 22: subbyte = 255; break;
case (unsigned char) 23: subbyte = 135; break;
case (unsigned char) 24: subbyte = 52; break;
case (unsigned char) 25: subbyte = 142; break;
case (unsigned char) 26: subbyte = 67; break;
case (unsigned char) 27: subbyte = 68; break;
case (unsigned char) 28: subbyte = 196; break;
case (unsigned char) 29: subbyte = 222; break;
case (unsigned char) 30: subbyte = 233; break;
case (unsigned char) 31: subbyte = 203; break;
case (unsigned char) 32: subbyte = 84; break;
case (unsigned char) 33: subbyte = 123; break;
case (unsigned char) 34: subbyte = 148; break;
case (unsigned char) 35: subbyte = 50; break;
case (unsigned char) 36: subbyte = 166; break;
case (unsigned char) 37: subbyte = 194; break;
case (unsigned char) 38: subbyte = 35; break;
case (unsigned char) 39: subbyte = 61; break;
case (unsigned char) 40: subbyte = 238; break;
case (unsigned char) 41: subbyte = 76; break;
case (unsigned char) 42: subbyte = 149; break;
case (unsigned char) 43: subbyte = 11; break;
case (unsigned char) 44: subbyte = 66; break;
case (unsigned char) 45: subbyte = 250; break;
case (unsigned char) 46: subbyte = 195; break;
case (unsigned char) 47: subbyte = 78; break;
case (unsigned char) 48: subbyte = 8; break;
case (unsigned char) 49: subbyte = 46; break;
case (unsigned char) 50: subbyte = 161; break;
case (unsigned char) 51: subbyte = 102; break;
case (unsigned char) 52: subbyte = 40; break;
case (unsigned char) 53: subbyte = 217; break;
case (unsigned char) 54: subbyte = 36; break;
case (unsigned char) 55: subbyte = 178; break;
case (unsigned char) 56: subbyte = 118; break;
case (unsigned char) 57: subbyte = 91; break;
case (unsigned char) 58: subbyte = 162; break;
case (unsigned char) 59: subbyte = 73; break;
case (unsigned char) 60: subbyte = 109; break;
case (unsigned char) 61: subbyte = 139; break;
case (unsigned char) 62: subbyte = 209; break;
case (unsigned char) 63: subbyte = 37; break;
case (unsigned char) 64: subbyte = 114; break;
case (unsigned char) 65: subbyte = 248; break;
case (unsigned char) 66: subbyte = 246; break;
case (unsigned char) 67: subbyte = 100; break;
case (unsigned char) 68: subbyte = 134; break;
case (unsigned char) 69: subbyte = 104; break;
case (unsigned char) 70: subbyte = 152; break;
case (unsigned char) 71: subbyte = 22; break;
case (unsigned char) 72: subbyte = 212; break;
case (unsigned char) 73: subbyte = 164; break;
case (unsigned char) 74: subbyte = 92; break;
case (unsigned char) 75: subbyte = 204; break;
case (unsigned char) 76: subbyte = 93; break;
case (unsigned char) 77: subbyte = 101; break;
case (unsigned char) 78: subbyte = 182; break;
case (unsigned char) 79: subbyte = 146; break;
case (unsigned char) 80: subbyte = 108; break;
case (unsigned char) 81: subbyte = 112; break;
case (unsigned char) 82: subbyte = 72; break;
case (unsigned char) 83: subbyte = 80; break;
case (unsigned char) 84: subbyte = 253; break;
case (unsigned char) 85: subbyte = 237; break;
case (unsigned char) 86: subbyte = 185; break;
case (unsigned char) 87: subbyte = 218; break;
case (unsigned char) 88: subbyte = 94; break;
case (unsigned char) 89: subbyte = 21; break;
case (unsigned char) 90: subbyte = 70; break;
case (unsigned char) 91: subbyte = 87; break;
case (unsigned char) 92: subbyte = 167; break;
case (unsigned char) 93: subbyte = 141; break;
case (unsigned char) 94: subbyte = 157; break;
case (unsigned char) 95: subbyte = 132; break;
case (unsigned char) 96: subbyte = 144; break;
case (unsigned char) 97: subbyte = 216; break;
case (unsigned char) 98: subbyte = 171; break;
case (unsigned char) 99: subbyte = 0; break;
case (unsigned char) 100: subbyte = 140; break;
case (unsigned char) 101: subbyte = 188; break;
case (unsigned char) 102: subbyte = 211; break;
case (unsigned char) 103: subbyte = 10; break;
case (unsigned char) 104: subbyte = 247; break;
case (unsigned char) 105: subbyte = 228; break;
case (unsigned char) 106: subbyte = 88; break;
case (unsigned char) 107: subbyte = 5; break;
case (unsigned char) 108: subbyte = 184; break;
case (unsigned char) 109: subbyte = 179; break;
case (unsigned char) 110: subbyte = 69; break;
case (unsigned char) 111: subbyte = 6; break;
case (unsigned char) 112: subbyte = 208; break;
case (unsigned char) 113: subbyte = 44; break;
case (unsigned char) 114: subbyte = 30; break;
case (unsigned char) 115: subbyte = 143; break;
case (unsigned char) 116: subbyte = 202; break;
case (unsigned char) 117: subbyte = 63; break;
case (unsigned char) 118: subbyte = 15; break;
case (unsigned char) 119: subbyte = 2; break;
case (unsigned char) 120: subbyte = 193; break;
case (unsigned char) 121: subbyte = 175; break;
case (unsigned char) 122: subbyte = 189; break;
case (unsigned char) 123: subbyte = 3; break;
case (unsigned char) 124: subbyte = 1; break;
case (unsigned char) 125: subbyte = 19; break;
case (unsigned char) 126: subbyte = 138; break;
case (unsigned char) 127: subbyte = 107; break;
case (unsigned char) 128: subbyte = 58; break;
case (unsigned char) 129: subbyte = 145; break;
case (unsigned char) 130: subbyte = 17; break;
case (unsigned char) 131: subbyte = 65; break;
case (unsigned char) 132: subbyte = 79; break;
case (unsigned char) 133: subbyte = 103; break;
case (unsigned char) 134: subbyte = 220; break;
case (unsigned char) 135: subbyte = 234; break;
case (unsigned char) 136: subbyte = 151; break;
case (unsigned char) 137: subbyte = 242; break;
case (unsigned char) 138: subbyte = 207; break;
case (unsigned char) 139: subbyte = 206; break;
case (unsigned char) 140: subbyte = 240; break;
case (unsigned char) 141: subbyte = 180; break;
case (unsigned char) 142: subbyte = 230; break;
case (unsigned char) 143: subbyte = 115; break;
case (unsigned char) 144: subbyte = 150; break;
case (unsigned char) 145: subbyte = 172; break;
case (unsigned char) 146: subbyte = 116; break;
case (unsigned char) 147: subbyte = 34; break;
case (unsigned char) 148: subbyte = 231; break;
case (unsigned char) 149: subbyte = 173; break;
case (unsigned char) 150: subbyte = 53; break;
case (unsigned char) 151: subbyte = 133; break;
case (unsigned char) 152: subbyte = 226; break;
case (unsigned char) 153: subbyte = 249; break;
case (unsigned char) 154: subbyte = 55; break;
case (unsigned char) 155: subbyte = 232; break;
case (unsigned char) 156: subbyte = 28; break;
case (unsigned char) 157: subbyte = 117; break;
case (unsigned char) 158: subbyte = 223; break;
case (unsigned char) 159: subbyte = 110; break;
case (unsigned char) 160: subbyte = 71; break;
case (unsigned char) 161: subbyte = 241; break;
case (unsigned char) 162: subbyte = 26; break;
case (unsigned char) 163: subbyte = 113; break;
case (unsigned char) 164: subbyte = 29; break;
case (unsigned char) 165: subbyte = 41; break;
case (unsigned char) 166: subbyte = 197; break;
case (unsigned char) 167: subbyte = 137; break;
case (unsigned char) 168: subbyte = 111; break;
case (unsigned char) 169: subbyte = 183; break;
case (unsigned char) 170: subbyte = 98; break;
case (unsigned char) 171: subbyte = 14; break;
case (unsigned char) 172: subbyte = 170; break;
case (unsigned char) 173: subbyte = 24; break;
case (unsigned char) 174: subbyte = 190; break;
case (unsigned char) 175: subbyte = 27; break;
case (unsigned char) 176: subbyte = 252; break;
case (unsigned char) 177: subbyte = 86; break;
case (unsigned char) 178: subbyte = 62; break;
case (unsigned char) 179: subbyte = 75; break;
case (unsigned char) 180: subbyte = 198; break;
case (unsigned char) 181: subbyte = 210; break;
case (unsigned char) 182: subbyte = 121; break;
case (unsigned char) 183: subbyte = 32; break;
case (unsigned char) 184: subbyte = 154; break;
case (unsigned char) 185: subbyte = 219; break;
case (unsigned char) 186: subbyte = 192; break;
case (unsigned char) 187: subbyte = 254; break;
case (unsigned char) 188: subbyte = 120; break;
case (unsigned char) 189: subbyte = 205; break;
case (unsigned char) 190: subbyte = 90; break;
case (unsigned char) 191: subbyte = 244; break;
case (unsigned char) 192: subbyte = 31; break;
case (unsigned char) 193: subbyte = 221; break;
case (unsigned char) 194: subbyte = 168; break;
case (unsigned char) 195: subbyte = 51; break;
case (unsigned char) 196: subbyte = 136; break;
case (unsigned char) 197: subbyte = 7; break;
case (unsigned char) 198: subbyte = 199; break;
case (unsigned char) 199: subbyte = 49; break;
case (unsigned char) 200: subbyte = 177; break;
case (unsigned char) 201: subbyte = 18; break;
case (unsigned char) 202: subbyte = 16; break;
case (unsigned char) 203: subbyte = 89; break;
case (unsigned char) 204: subbyte = 39; break;
case (unsigned char) 205: subbyte = 128; break;
case (unsigned char) 206: subbyte = 236; break;
case (unsigned char) 207: subbyte = 95; break;
case (unsigned char) 208: subbyte = 96; break;
case (unsigned char) 209: subbyte = 81; break;
case (unsigned char) 210: subbyte = 127; break;
case (unsigned char) 211: subbyte = 169; break;
case (unsigned char) 212: subbyte = 25; break;
case (unsigned char) 213: subbyte = 181; break;
case (unsigned char) 214: subbyte = 74; break;
case (unsigned char) 215: subbyte = 13; break;
case (unsigned char) 216: subbyte = 45; break;
case (unsigned char) 217: subbyte = 229; break;
case (unsigned char) 218: subbyte = 122; break;
case (unsigned char) 219: subbyte = 159; break;
case (unsigned char) 220: subbyte = 147; break;
case (unsigned char) 221: subbyte = 201; break;
case (unsigned char) 222: subbyte = 156; break;
case (unsigned char) 223: subbyte = 239; break;
case (unsigned char) 224: subbyte = 160; break;
case (unsigned char) 225: subbyte = 224; break;
case (unsigned char) 226: subbyte = 59; break;
case (unsigned char) 227: subbyte = 77; break;
case (unsigned char) 228: subbyte = 174; break;
case (unsigned char) 229: subbyte = 42; break;
case (unsigned char) 230: subbyte = 245; break;
case (unsigned char) 231: subbyte = 176; break;
case (unsigned char) 232: subbyte = 200; break;
case (unsigned char) 233: subbyte = 235; break;
case (unsigned char) 234: subbyte = 187; break;
case (unsigned char) 235: subbyte = 60; break;
case (unsigned char) 236: subbyte = 131; break;
case (unsigned char) 237: subbyte = 83; break;
case (unsigned char) 238: subbyte = 153; break;
case (unsigned char) 239: subbyte = 97; break;
case (unsigned char) 240: subbyte = 23; break;
case (unsigned char) 241: subbyte = 43; break;
case (unsigned char) 242: subbyte = 4; break;
case (unsigned char) 243: subbyte = 126; break;
case (unsigned char) 244: subbyte = 186; break;
case (unsigned char) 245: subbyte = 119; break;
case (unsigned char) 246: subbyte = 214; break;
case (unsigned char) 247: subbyte = 38; break;
case (unsigned char) 248: subbyte = 225; break;
case (unsigned char) 249: subbyte = 105; break;
case (unsigned char) 250: subbyte = 20; break;
case (unsigned char) 251: subbyte = 99; break;
case (unsigned char) 252: subbyte = 85; break;
case (unsigned char) 253: subbyte = 33; break;
case (unsigned char) 254: subbyte = 12; break;
case (unsigned char) 255: subbyte = 125; break;
}
struct byte result;
result.b = subbyte;
return result;
}

static const struct byte Rcon[11] = {{0x8d}, {0x01}, {0x02}, {0x04}, {0x08}, {0x10}, {0x20}, {0x40}, {0x80}, {0x1b}, {0x36}};

// This function produces Nb(Nr+1) round keys. The round keys are used in each round to decrypt the states. 
static void KeyExpansion(struct byte *RoundKey, struct byte *Key)
{ 
  unsigned i, j, k;
  struct byte tempa[4]; // Used for the column/row operations
  
  // The first round key is the key itself.
  for (i = 0; i < Nk; ++i)
  {
    RoundKey[(i * 4) + 0] = Key[(i * 4) + 0];
    RoundKey[(i * 4) + 1] = Key[(i * 4) + 1];
    RoundKey[(i * 4) + 2] = Key[(i * 4) + 2];
    RoundKey[(i * 4) + 3] = Key[(i * 4) + 3];
  }

  // All other round keys are found from the previous round keys.
  for (i = Nk; i < Nb * (Nr + 1); ++i)
  {
    {
      k = (i - 1) * 4;
      tempa[0]=RoundKey[k + 0];
      tempa[1]=RoundKey[k + 1];
      tempa[2]=RoundKey[k + 2];
      tempa[3]=RoundKey[k + 3];

    }

    if (i % Nk == 0)
    {
      // This function shifts the 4 bytes in a word to the left once.
      // [a0,a1,a2,a3] becomes [a1,a2,a3,a0]

      // Function RotWord()
      {
        const struct byte u8tmp = tempa[0];
        tempa[0] = tempa[1];
        tempa[1] = tempa[2];
        tempa[2] = tempa[3];
        tempa[3] = u8tmp;
      }

      // SubWord() is a function that takes a four-byte input word and 
      // applies the S-box to each of the four bytes to produce an output word.

      // Function Subword()
      {
        tempa[0] = sbox(tempa[0]);
        tempa[1] = sbox(tempa[1]);
        tempa[2] = sbox(tempa[2]);
        tempa[3] = sbox(tempa[3]);
      }

      tempa[0].b = tempa[0].b ^ Rcon[i/Nk].b;
    }

    j = i * 4; k=(i - Nk) * 4;
    RoundKey[j + 0].b = RoundKey[k + 0].b ^ tempa[0].b;
    RoundKey[j + 1].b = RoundKey[k + 1].b ^ tempa[1].b;
    RoundKey[j + 2].b = RoundKey[k + 2].b ^ tempa[2].b;
    RoundKey[j + 3].b = RoundKey[k + 3].b ^ tempa[3].b;
  }
}

// This function adds the round key to state.
// The round key is added to the state by an XOR function.
static void AddRoundKey(int round, struct byte state[4][4], const struct byte* RoundKey)
{
  int i,j;
  for (i = 0; i < 4; ++i)
  {
    for (j = 0; j < 4; ++j)
    {
      (state)[i][j].b ^= RoundKey[(round * Nb * 4) + (i * Nb) + j].b;
    }
  }
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
static void SubBytes(struct byte state[4][4])
{
  int i, j;
  for (i = 0; i < 4; ++i)
  {
    for (j = 0; j < 4; ++j)
    {
      (state)[j][i] = sbox((state)[j][i]);
    }
  }
}

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
static void ShiftRows(struct byte state[4][4])
{
  struct byte temp;

  // Rotate first row 1 columns to left  
  temp           = (state)[0][1];
  (state)[0][1] = (state)[1][1];
  (state)[1][1] = (state)[2][1];
  (state)[2][1] = (state)[3][1];
  (state)[3][1] = temp;

  // Rotate second row 2 columns to left  
  temp           = (state)[0][2];
  (state)[0][2] = (state)[2][2];
  (state)[2][2] = temp;

  temp           = (state)[1][2];
  (state)[1][2] = (state)[3][2];
  (state)[3][2] = temp;

  // Rotate third row 3 columns to left
  temp           = (state)[0][3];
  (state)[0][3] = (state)[3][3];
  (state)[3][3] = (state)[2][3];
  (state)[2][3] = (state)[1][3];
  (state)[1][3] = temp;
}

static unsigned char xtime(unsigned char x)
{
  return ((x<<1) ^ (((x>>7) & 1) * (unsigned char)0x1b));
}

// MixColumns function mixes the columns of the state matrix
static void MixColumns(struct byte state[4][4])
{
  int i;
  struct byte Tmp, Tm, t;
  for (i = 0; i < 4; ++i)
  {  
    t   = (state)[i][0];
    Tmp.b = (state)[i][0].b ^ (state)[i][1].b ^ (state)[i][2].b ^ (state)[i][3].b ;
    Tm.b  = (state)[i][0].b ^ (state)[i][1].b ; Tm.b = xtime(Tm.b);  (state)[i][0].b ^= Tm.b ^ Tmp.b ;
    Tm.b  = (state)[i][1].b ^ (state)[i][2].b ; Tm.b = xtime(Tm.b);  (state)[i][1].b ^= Tm.b ^ Tmp.b ;
    Tm.b  = (state)[i][2].b ^ (state)[i][3].b ; Tm.b = xtime(Tm.b);  (state)[i][2].b ^= Tm.b ^ Tmp.b ;
    Tm.b  = (state)[i][3].b ^ t.b ;              Tm.b = xtime(Tm.b);  (state)[i][3].b ^= Tm.b ^ Tmp.b ;
  }
}

static unsigned char Multiply(unsigned char x, unsigned char y)
{
  return (((y & 1) * x) ^
       ((y>>1 & 1) * xtime(x)) ^
       ((y>>2 & 1) * xtime(xtime(x))) ^
       ((y>>3 & 1) * xtime(xtime(xtime(x)))) ^
       ((y>>4 & 1) * xtime(xtime(xtime(xtime(x)))))); /* this last call to xtime() can be omitted */
}

// MixColumns function mixes the columns of the state matrix.
// The method used to multiply may be difficult to understand for the inexperienced.
// Please use the references to gain more information.
static void InvMixColumns(struct byte state[4][4])
{
  int i;
  unsigned char a, b, c, d;
  for (i = 0; i < 4; ++i)
  { 
    a = (state)[i][0].b;
    b = (state)[i][1].b;
    c = (state)[i][2].b;
    d = (state)[i][3].b;

    (state)[i][0].b = Multiply(a, 0x0e) ^ Multiply(b, 0x0b) ^ Multiply(c, 0x0d) ^ Multiply(d, 0x09);
    (state)[i][1].b = Multiply(a, 0x09) ^ Multiply(b, 0x0e) ^ Multiply(c, 0x0b) ^ Multiply(d, 0x0d);
    (state)[i][2].b = Multiply(a, 0x0d) ^ Multiply(b, 0x09) ^ Multiply(c, 0x0e) ^ Multiply(d, 0x0b);
    (state)[i][3].b = Multiply(a, 0x0b) ^ Multiply(b, 0x0d) ^ Multiply(c, 0x09) ^ Multiply(d, 0x0e);
  }
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
static void InvSubBytes(struct byte state[4][4])
{
  int i, j;
  for (i = 0; i < 4; ++i)
  {
    for (j = 0; j < 4; ++j)
    {
      (state)[j][i] = revsbox((state)[j][i]);
    }
  }
}

static void InvShiftRows(struct byte state[4][4])
{
  struct byte temp;

  // Rotate first row 1 columns to right  
  temp = (state)[3][1];
  (state)[3][1] = (state)[2][1];
  (state)[2][1] = (state)[1][1];
  (state)[1][1] = (state)[0][1];
  (state)[0][1] = temp;

  // Rotate second row 2 columns to right 
  temp = (state)[0][2];
  (state)[0][2] = (state)[2][2];
  (state)[2][2] = temp;

  temp = (state)[1][2];
  (state)[1][2] = (state)[3][2];
  (state)[3][2] = temp;

  // Rotate third row 3 columns to right
  temp = (state)[0][3];
  (state)[0][3] = (state)[1][3];
  (state)[1][3] = (state)[2][3];
  (state)[2][3] = (state)[3][3];
  (state)[3][3] = temp;
}

// Cipher is the main function that encrypts the PlainText.
static void Cipher(struct byte state[4][4], const struct byte* RoundKey)
{
  int round = 0;

  // Add the First round key to the state before starting the rounds.
  AddRoundKey(0, state, RoundKey);

  // There will be Nr rounds.
  // The first Nr-1 rounds are identical.
  // These Nr rounds are executed in the loop below.
  // Last one without MixColumns()
  for (round = 1; ; ++round)
  {
    SubBytes(state);
    ShiftRows(state);
    if (round == Nr) {
      break;
    }
    MixColumns(state);
    AddRoundKey(round, state, RoundKey);
  }
  // Add round key to last round
  AddRoundKey(Nr, state, RoundKey);
}

static void InvCipher(struct byte state[4][4], const struct byte* RoundKey)
{
  int round = 0;

  // Add the First round key to the state before starting the rounds.
  AddRoundKey(Nr, state, RoundKey);

  // There will be Nr rounds.
  // The first Nr-1 rounds are identical.
  // These Nr rounds are executed in the loop below.
  // Last one without InvMixColumn()
  for (round = (Nr - 1); ; --round)
  {
    InvShiftRows(state);
    InvSubBytes(state);
    AddRoundKey(round, state, RoundKey);
    if (round == 0) {
      break;
    }
    InvMixColumns(state);
  }

}

#endif /* !HEADER_AES_H */