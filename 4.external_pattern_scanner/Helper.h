#pragma once
#include <Windows.h>  //DWORD, HANDLE
#include <TlHelp32.h> //CreateToolhelp32Snapshot
#include <tchar.h>    //_tcscmp
#include <Psapi.h>    //GetModuleInformation
#include <vector>

using namespace std;

class Helper
{
public:
	Helper();
	Helper(DWORD pID);
	~Helper();
	DWORD GetModuleBaseAddress(TCHAR* lpszModuleName);
	DWORD GetDynamicAddress(DWORD baseAddress, vector<DWORD> offsets);
	DWORD GetAddressFromSignature(vector<int> signature);
	void SetpID(DWORD pID);
	void SetpBaseAddress(char moduleName[]);
	DWORD GetpID();
	HANDLE GetprocessHandle();
	
private:
	DWORD pID;
	DWORD pBaseAddress; //Base Address of exe
	DWORD pSize;		//Size of exe module
	HANDLE processHandle;
};
