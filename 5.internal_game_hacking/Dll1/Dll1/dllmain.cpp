// dllmain.cpp : Defines the entry point for the DLL application.
#include <Windows.h>
#include <iostream>
#include <vector>

HMODULE myhModule;

DWORD __stdcall EjectThread(LPVOID lpParameter) {
	Sleep(100);
	FreeLibraryAndExitThread(myhModule, 0);
}

DWORD GetAddressFromSignature(std::vector<int> signature, DWORD startaddress = 0, DWORD endaddress = 0) {
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	if (startaddress == 0) {
		startaddress = (DWORD)(si.lpMinimumApplicationAddress);
	}
	if (endaddress == 0) {
		endaddress = (DWORD)(si.lpMaximumApplicationAddress);
	}

	MEMORY_BASIC_INFORMATION mbi{ 0 };
	DWORD protectflags = (PAGE_GUARD | PAGE_NOCACHE | PAGE_NOACCESS);

	for (DWORD i = startaddress; i < endaddress - signature.size(); i++) {
		//std::cout << "scanning: " << std::hex << i << std::endl;
		if (VirtualQuery((LPCVOID)i, &mbi, sizeof(mbi))) {
			if (mbi.Protect & protectflags || !(mbi.State & MEM_COMMIT)) {
				std::cout << "Bad Region! Region Base Address: " << mbi.BaseAddress << " | Region end address: " << std::hex << (int)((DWORD)mbi.BaseAddress + mbi.RegionSize) << std::endl;
				i += mbi.RegionSize;
				continue; // if bad adress then dont read from it
			}
			std::cout << "Good Region! Region Base Address: " << mbi.BaseAddress << " | Region end address: " << std::hex << (int)((DWORD)mbi.BaseAddress + mbi.RegionSize) << std::endl;
			for (DWORD k = (DWORD)mbi.BaseAddress; k < (DWORD)mbi.BaseAddress + mbi.RegionSize - signature.size(); k++) {
				for (DWORD j = 0; j < signature.size(); j++) {
					if (signature.at(j) != -1 && signature.at(j) != *(byte*)(k + j))
						break;
					if (j + 1 == signature.size())
						return k;
				}
			}
			i = (DWORD)mbi.BaseAddress + mbi.RegionSize;
		}
	}
	return NULL;
}

struct _Player {
	void* pThis = NULL;
	bool bghost = false;
	DWORD ghostoffset = 0x00000549;
	DWORD xoffset = 0x20;
	DWORD yoffset = 0x24;
	DWORD xteleport = 0;
	DWORD yteleport = 0;
}Player;

DWORD GetPlayerBase() {
	std::vector<int> sig = { 0xA1, -1, -1, -1, -1, 0x8B, 0x15, -1, -1, -1, -1, 0x3B, 0x50, 0x04, 0x73, 0x05, 0x8B, 0x44, 0x90, 0x08 };
	DWORD Entry = GetAddressFromSignature(sig, 0x4A000000, 0x50000000);
	if (Entry == NULL)
		Entry = GetAddressFromSignature(sig, 0x1F000000, 0x4A000000);
	if (Entry == NULL)
		Entry = GetAddressFromSignature(sig);
	DWORD eax = *(DWORD*)(*(DWORD*)(Entry + 0x01));
	DWORD edx = *(DWORD*)(*(DWORD*)(Entry + 0x07));
	return *(DWORD*)(eax + edx * 4 + 0x08);
}

DWORD WINAPI Menue() {
	AllocConsole();
	FILE* fp;
	freopen_s(&fp, "CONOUT$", "w", stdout); // output only
	std::cout << "Press 0 to Exit | Press 1 for Scanning" << std::endl;
	while (1) {
		Sleep(100);
		if (GetAsyncKeyState(VK_NUMPAD0))
			break;
		if (GetAsyncKeyState(VK_NUMPAD1)) {
			std::cout << "Starting ghost function" << std::endl;
			if (Player.pThis == NULL)
				Player.pThis = (void*)GetPlayerBase();
			if (!Player.bghost) {
				*(byte*)((DWORD)Player.pThis + Player.ghostoffset) = 0x01; //turn ghost on
			}
			else {
				*(byte*)((DWORD)Player.pThis + Player.ghostoffset) = 0x00; //turn ghost off
			}
			Player.bghost = !Player.bghost;
			Sleep(500);
		}
		if (GetAsyncKeyState(VK_NUMPAD2)) {
			std::cout << "setting teleport location" << std::endl;
			if (Player.pThis == NULL)
				Player.pThis = (void*)GetPlayerBase();
			Player.xteleport = *(DWORD*)((DWORD)Player.pThis + Player.xoffset);
			Player.yteleport = *(DWORD*)((DWORD)Player.pThis + Player.yoffset);
		}
		if (GetAsyncKeyState(VK_NUMPAD3)) {
			if (Player.xteleport != 0) { // only teleport if we have a location set
				*(DWORD*)((DWORD)Player.pThis + Player.xoffset) = Player.xteleport;
				*(DWORD*)((DWORD)Player.pThis + Player.yoffset) = Player.yteleport;
			}
		}
	}
	fclose(fp);
	FreeConsole();
	CreateThread(0, 0, EjectThread, 0, 0, 0);
	int i = 0;
	return 0;
}


BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		myhModule = hModule;
		CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)Menue, NULL, 0, NULL);
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}