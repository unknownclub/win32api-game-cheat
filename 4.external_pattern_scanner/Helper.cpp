#include "Helper.h"

Helper::Helper()
{
	pID = NULL;
	processHandle = NULL;
}

Helper::Helper(DWORD pID) {
	this->pID = pID;
	HANDLE processHandle = NULL;
	processHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pID);
	if (processHandle == INVALID_HANDLE_VALUE || processHandle == NULL) {
		std::cerr << "Failed to open process -- invalid handle" << std::endl;
		std::cerr << "Error code: " << GetLastError() << std::endl;
		throw "Failed to open process";
	}
	else {
		//std::cout << "Helper:: process handle sucessfully created!" << std::endl;
		this->processHandle = processHandle;
	}
}


Helper::~Helper()
{
	CloseHandle(this->processHandle);
}

void Helper::SetpID(DWORD pID) {this->pID = pID;}
DWORD Helper::GetpID(){ return this->pID; }
HANDLE Helper::GetprocessHandle() { return this->processHandle; }

DWORD Helper::GetModuleBaseAddress(TCHAR* lpszModuleName) {
	DWORD dwModuleBaseAddress = 0;
	HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pID);
	MODULEENTRY32 ModuleEntry32 = { 0 };
	ModuleEntry32.dwSize = sizeof(MODULEENTRY32);

	if (Module32First(hSnapshot, &ModuleEntry32))
	{
		do {
			if (_tcscmp(ModuleEntry32.szModule, lpszModuleName) == 0)
			{
				dwModuleBaseAddress = (DWORD)ModuleEntry32.modBaseAddr;
				break;
			}
		} while (Module32Next(hSnapshot, &ModuleEntry32));


	}
	CloseHandle(hSnapshot);
	return dwModuleBaseAddress;
}

DWORD Helper::GetDynamicAddress(DWORD baseAddress, vector<DWORD> offsets) {
	DWORD dynamicAddress = baseAddress;
	for (int i = 0; i < offsets.size() - 1; i++)
	{
		ReadProcessMemory(this->processHandle, (LPCVOID)(dynamicAddress + offsets.at(i)), &dynamicAddress, sizeof(offsets.at(i)), NULL);
		//std::cout << "Current Adress: " << std::hex << healthAddress << std::endl;
	}
	dynamicAddress += offsets.at(offsets.size() - 1);
	return dynamicAddress;
}

void Helper::SetpBaseAddress(char moduleName[]) {
	this->pBaseAddress = this->GetModuleBaseAddress(_T(moduleName));
}

DWORD Helper::GetAddressFromSignature(vector<int> signature) {
	if (this->pBaseAddress == NULL || this->processHandle == NULL) {
		return NULL;
	}
	std::vector<byte> memBuffer(this->pSize);
	if (!ReadProcessMemory(this->processHandle, (LPCVOID)(this->pBaseAddress), memBuffer.data(), this->pSize, NULL)) {
		std::cout << GetLastError() << std::endl;
		return NULL;
	}
	for (int i = 0; i < this->pSize; i++){
		for (DWORD j = 0; j < signature.size();j++) {
			if (signature.at(j) != -1 && signature.at(j) != memBuffer.at(i + j))
				//std::cout << std::hex << signature.at(j) << std::hex << memBuffer[i + j] << std::endl;
				break;
			if(signature.at(j) == memBuffer.at(i + j) && j>0)
				std::cout << std::hex << int(signature.at(j)) << std::hex << int(memBuffer.at(i + j)) << j <<std::endl;
			if(j+1 == signature.size())
				return this->pBaseAddress + i;
		}
	}
	return NULL;
}
