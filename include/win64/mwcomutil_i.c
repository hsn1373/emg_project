

/* this ALWAYS GENERATED file contains the IIDs and CLSIDs */

/* link this file in with the server and any clients */


 /* File created by MIDL compiler version 8.00.0603 */
/* at Thu May 24 23:46:29 2018
 */
/* Compiler settings for win64\mwcomutil.idl:
    Oicf, W1, Zp8, env=Win64 (32b run), target_arch=IA64 8.00.0603 
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
/* @@MIDL_FILE_HEADING(  ) */

#pragma warning( disable: 4049 )  /* more than 64k source lines */


#ifdef __cplusplus
extern "C"{
#endif 


#include <rpc.h>
#include <rpcndr.h>

#ifdef _MIDL_USE_GUIDDEF_

#ifndef INITGUID
#define INITGUID
#include <guiddef.h>
#undef INITGUID
#else
#include <guiddef.h>
#endif

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        DEFINE_GUID(name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8)

#else // !_MIDL_USE_GUIDDEF_

#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        const type name = {l,w1,w2,{b1,b2,b3,b4,b5,b6,b7,b8}}

#endif !_MIDL_USE_GUIDDEF_

MIDL_DEFINE_GUID(IID, IID_IMWUtil,0xC47EA90E,0x56D1,0x11d5,0xB1,0x59,0x00,0xD0,0xB7,0xBA,0x75,0x44);


MIDL_DEFINE_GUID(IID, LIBID_MWComUtil,0x69608C92,0x584A,0x4C33,0xAC,0x93,0xBE,0x0F,0x40,0xE3,0x0A,0xE4);


MIDL_DEFINE_GUID(CLSID, CLSID_MWField,0x34698995,0x4A6B,0x4215,0x82,0x50,0x5B,0xBD,0x6C,0xFF,0xAF,0xA8);


MIDL_DEFINE_GUID(CLSID, CLSID_MWStruct,0x53CC3350,0x189B,0x4076,0x8F,0x71,0x1B,0x3A,0x7A,0xA1,0xA1,0x44);


MIDL_DEFINE_GUID(CLSID, CLSID_MWComplex,0xE2DF7FC7,0xDDAB,0x4DFA,0xAF,0x9F,0x78,0x60,0x96,0x80,0x2A,0x15);


MIDL_DEFINE_GUID(CLSID, CLSID_MWSparse,0x0A27B008,0x9475,0x4271,0x94,0xAC,0x82,0xC1,0xDE,0xA7,0x1A,0xC7);


MIDL_DEFINE_GUID(CLSID, CLSID_MWArg,0xF172AF8E,0xE19E,0x43B2,0x86,0x3F,0x82,0x4D,0x1D,0x2E,0xF2,0x83);


MIDL_DEFINE_GUID(CLSID, CLSID_MWArrayFormatFlags,0x76436BF6,0xCC9D,0x4A9E,0xA0,0x65,0xF0,0x92,0x2F,0x9A,0x5E,0x0F);


MIDL_DEFINE_GUID(CLSID, CLSID_MWDataConversionFlags,0x5F5B4B4B,0x6B82,0x46FF,0x91,0x8D,0xEE,0x32,0x23,0x4B,0x20,0x7D);


MIDL_DEFINE_GUID(CLSID, CLSID_MWUtil,0xD291A107,0x30FB,0x436A,0x99,0xD2,0xCE,0x24,0x9C,0xDB,0xA8,0x02);


MIDL_DEFINE_GUID(CLSID, CLSID_MWFlags,0x0354E886,0x264E,0x49DA,0xB5,0xF1,0x9A,0xEC,0x61,0x9A,0xF6,0x7D);

#undef MIDL_DEFINE_GUID

#ifdef __cplusplus
}
#endif



