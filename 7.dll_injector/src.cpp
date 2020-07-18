#include<Windows.h> //DWORD
#include <iostream>
#include <string>
#include <psapi.h> //EnumProcessModules
#include <VersionHelpers.h>
#include <atlstr.h> // CString

#define CREATE_THREAD_ACCESS (PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ)

BOOL InjectDLL(DWORD ProcessID)
{
    LPCSTR DLL_PATH = "E:\\Videos\\11 dll injector\\vs Project\\DllInjector\\Debug\\Terraria_dll.dll";
    LPVOID LoadLibAddy, RemoteString;

    if (!ProcessID)
        return false;

    HANDLE Proc = OpenProcess(CREATE_THREAD_ACCESS, FALSE, ProcessID);

    if (!Proc)
    {
        std::cout << "OpenProcess() failed: " << GetLastError() << std::endl;
        return false;
    }

    LoadLibAddy = (LPVOID)GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");

    RemoteString = (LPVOID)VirtualAllocEx(Proc, NULL, strlen(DLL_PATH) + 1, MEM_COMMIT, PAGE_READWRITE);
    WriteProcessMemory(Proc, RemoteString, (LPVOID)DLL_PATH, strlen(DLL_PATH)+1, NULL);
    CreateRemoteThread(Proc, NULL, NULL, (LPTHREAD_START_ROUTINE)LoadLibAddy, RemoteString, NULL, NULL);

    CloseHandle(Proc);

    return true;
}

//BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam);

BOOL CALLBACK EnumWindowsProc(HWND hWnd, LPARAM lParam) {
    DWORD dwThreadId, dwProcessId;
    HINSTANCE hInstance;
    char String[255];
    if (!hWnd)
        return TRUE;		// Not a window
    if (!::IsWindowVisible(hWnd))
        return TRUE;		// Not visible
    if (!SendMessage(hWnd, WM_GETTEXT, sizeof(String), (LPARAM)String))
        return TRUE;		// No window title
    hInstance = (HINSTANCE)GetWindowLong(hWnd, GWL_HINSTANCE);
    dwThreadId = GetWindowThreadProcessId(hWnd, &dwProcessId);
    std::cout << "PID: " << dwProcessId << '\t' << String << '\t' << std::endl;
    return TRUE;
}

int main() {
    if (IsWindowsXPOrGreater()) {
        std::cout << "Available Targets:\n\n" <<std::endl;
        EnumWindows(EnumWindowsProc, NULL);
        std::cout << "\nPick Target ProcessID" << std::endl;
        DWORD PID;
        std::cin >> PID;
        InjectDLL(PID);
    }
    else {
        std::cout << "Method not supported by OS. Terminating" << std::endl;
        return 0;
    }

	return 0;
}