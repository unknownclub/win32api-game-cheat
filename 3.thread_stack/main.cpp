#include <Windows.h> //HWND, DWORD etc.
#include<TlHelp32.h>
#include <Psapi.h>
#include <iostream> // cout
//#include <tchar.h> // _tcscmp
#include <vector> //vector ...
#include "ntinfo.h"

std::vector<DWORD> threadList(DWORD pid) {
	/* solution from http://stackoverflow.com/questions/1206878/enumerating-threads-in-windows */
	std::vector<DWORD> vect = std::vector<DWORD>();
	HANDLE h = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	if (h == INVALID_HANDLE_VALUE)
		return vect;

	THREADENTRY32 te;
	te.dwSize = sizeof(te);
	if (Thread32First(h, &te)) {
		do {
			if (te.dwSize >= FIELD_OFFSET(THREADENTRY32, th32OwnerProcessID) +
				sizeof(te.th32OwnerProcessID)) {


				if (te.th32OwnerProcessID == pid) {
					//printf("PID: %04d Thread ID: 0x%04x\n", te.th32OwnerProcessID, te.th32ThreadID);
					vect.push_back(te.th32ThreadID);
				}

			}
			te.dwSize = sizeof(te);
		} while (Thread32Next(h, &te));
	}

	return vect;
}

DWORD GetThreadStartAddress(HANDLE processHandle, HANDLE hThread) {
	/* rewritten from https://github.com/cheat-engine/cheat-engine/blob/master/Cheat%20Engine/CEFuncProc.pas#L3080 */
	DWORD used = 0, ret = 0;
	DWORD stacktop = 0, result = 0;

	MODULEINFO mi;

	GetModuleInformation(processHandle, GetModuleHandle("kernel32.dll"), &mi, sizeof(mi));
	stacktop = (DWORD)GetThreadStackTopAddress_x86(processHandle, hThread);

	CloseHandle(hThread);

	if (stacktop) {
		//find the stack entry pointing to the function that calls "ExitXXXXXThread"
		//Fun thing to note: It's the first entry that points to a address in kernel32

		DWORD* buf32 = new DWORD[4096];

		if (ReadProcessMemory(processHandle, (LPCVOID)(stacktop - 4096), buf32, 4096, NULL)) {
			for (int i = 4096 / 4 - 1; i >= 0; --i) {
				if (buf32[i] >= (DWORD)mi.lpBaseOfDll && buf32[i] <= (DWORD)mi.lpBaseOfDll + mi.SizeOfImage) {
					result = stacktop - 4096 + i * 4;
					break;
				}

			}
		}

		delete buf32;
	}

	return result;
}




DWORD GetThreadstackStartAddress(int stackNumber, DWORD pID, HANDLE processHandle) {
	std::vector<DWORD> threadId = threadList(pID);
	int stackNum = 0;
	for (auto it = threadId.begin(); it != threadId.end(); ++it) {
		HANDLE threadHandle = OpenThread(THREAD_GET_CONTEXT | THREAD_QUERY_INFORMATION, FALSE, *it);
		DWORD threadStartAddress = GetThreadStartAddress(processHandle, threadHandle);
		printf("TID: 0x%04x = THREADSTACK%2d BASE ADDRESS: 0x%04x\n", *it, stackNum, threadStartAddress);
		if (stackNum == stackNumber) return threadStartAddress;
		stackNum++;
	}
}

int main() {

	HWND hGameWindow = FindWindow(NULL, "Zuma Deluxe 1.0");
	if (hGameWindow == NULL) {
		std::cout << "Start the game!" << std::endl;
		return 0;
	}
	DWORD pID = NULL; // ID of our Game
	GetWindowThreadProcessId(hGameWindow, &pID);
	HANDLE processHandle = NULL;
	processHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pID);
	if (processHandle == INVALID_HANDLE_VALUE || processHandle == NULL) { // error handling
		std::cout << "Failed to open process" << std::endl;
		return 0;
	}

	DWORD PointerBaseAddress = GetThreadstackStartAddress(0, pID, processHandle);
	DWORD offsetGameToBaseAdress = -0x000008C8;
	std::vector<DWORD> pointsOffsets{ 0x04, 0x04, 0x08, 0x58, 0xB8 };
	DWORD baseAddress = NULL;
	//Get value at gamebase+offset -> store it in baseAddress
	ReadProcessMemory(processHandle, (LPVOID)(PointerBaseAddress + offsetGameToBaseAdress), &baseAddress, sizeof(baseAddress), NULL);
	std::cout << "debugginfo: baseaddress = " << std::hex << baseAddress << std::endl;
	DWORD pointsAddress = baseAddress; //the Adress we need -> change now while going through offsets
	for (int i = 0; i < pointsOffsets.size() - 1; i++) // -1 because we dont want the value at the last offset
	{
		ReadProcessMemory(processHandle, (LPVOID)(pointsAddress + pointsOffsets.at(i)), &pointsAddress, sizeof(pointsAddress), NULL);
		std::cout << "debugginfo: Value at offset = " << std::hex << pointsAddress << std::endl;
	}
	pointsAddress += pointsOffsets.at(pointsOffsets.size() - 1); //Add Last offset -> done!!

	//"UI"
	std::cout << "Zuma Deluxe 1.0 H4CKs" << std::endl;
	std::cout << "Press Numpad 0 to EXIT" << std::endl;
	std::cout << "Press Numpad 1 to set lives" << std::endl;
	while (true) {
		Sleep(50);
		if (GetAsyncKeyState(VK_NUMPAD0)) { // Exit
			return 0;
		}
		if (GetAsyncKeyState(VK_NUMPAD1)) {//Mouseposition
			std::cout << "How many lives you want?" << std::endl;
			int newPoints = 0;
			std::cin >> newPoints;
			WriteProcessMemory(processHandle, (LPVOID)(pointsAddress), &newPoints, 4, 0);
		}
	}

}