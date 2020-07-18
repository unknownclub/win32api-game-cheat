#include <windows.h>
#include <thread>
#include <chrono>
#include <iostream>

using namespace std;

void press_key(SHORT virtual_key_code, int& down_time, SHORT virtual_key_code2 = NULL) {
    INPUT Input = { 0 };
    Input.type = INPUT_KEYBOARD;
    Input.ki.wVk = virtual_key_code;
    SendInput(1, &Input, sizeof(Input));
    ZeroMemory(&Input, sizeof(Input));
    Input.type = INPUT_KEYBOARD;
    Input.ki.wVk = virtual_key_code;
    Input.ki.dwFlags = KEYEVENTF_KEYUP;
    std::this_thread::sleep_for(std::chrono::milliseconds(down_time));
    SendInput(1, &Input, sizeof(Input));
    ZeroMemory(&Input, sizeof(Input));
    if (virtual_key_code2 != NULL) {
        Input.type = INPUT_KEYBOARD;
        Input.ki.wVk = virtual_key_code2;
        SendInput(1, &Input, sizeof(Input));
        ZeroMemory(&Input, sizeof(Input));
        Input.type = INPUT_KEYBOARD;
        Input.ki.wVk = virtual_key_code2;
        Input.ki.dwFlags = KEYEVENTF_KEYUP;
        std::this_thread::sleep_for(std::chrono::milliseconds(140));
        SendInput(1, &Input, sizeof(Input));
        ZeroMemory(&Input, sizeof(Input));
    }
}

int get_Bitmap(int x, int y, HDC& hdcMemory, int width = 700, int height = 200) {
    HDC hdcSource = GetDC(NULL);
    hdcMemory = CreateCompatibleDC(hdcSource);
    HBITMAP hBitmap = CreateCompatibleBitmap(hdcSource, width, height);
    HBITMAP hBitmapOld = (HBITMAP)SelectObject(hdcMemory, hBitmap);
    if (!BitBlt(hdcMemory, 0, 0, width, height, hdcSource, x, y, CAPTUREBLT | SRCCOPY)) {
        cout << "BitBlt failed!" << endl;
    }

    //clean up
    DeleteObject(hBitmapOld);
    DeleteObject(hBitmap);
    ReleaseDC(NULL, hdcSource);

    return 0;
}

void update_Bitmap(int x, int y, HDC& hdcMemory, bool& exit_flag, int width = 700, int height = 200) {
    while (!exit_flag) {
        get_Bitmap(x, y, hdcMemory, width = 700, height = 200);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    cout << "thread: update Bitmap stopped" << endl;
    return;
}

void jumper(bool& exit_flag, POINT tail, POINT& cactus_min, POINT& cactus_max, COLORREF threat_color, HDC& hdcMemory, SHORT& second_key, int& down_time) {
    while (!exit_flag) {
        for (int i = cactus_min.x + tail.x; i < cactus_max.x + tail.x; i = i + 4) {
            int j = cactus_min.y + tail.y;
            COLORREF color = GetPixel(hdcMemory, i, j);
            if (color == threat_color) {
                press_key(VK_SPACE, down_time, second_key);
                //cout << "Cactus!" << endl;
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    }
    cout << "thread: jumping stopped" << endl;
}

void dodger(bool& exit_flag, POINT tail, POINT& bird_coords, COLORREF threat_color, HDC& hdcMemory) {
    COLORREF color;
    while (!exit_flag) {
        for (int i = tail.x + bird_coords.x; i < tail.x + bird_coords.x + 30; i = i + 2) {
            color = GetPixel(hdcMemory, i, tail.y + bird_coords.y);
            if (color == threat_color) {
                //cout << "THIS IS BAT LAND!" << endl;
                int temp = 320;
                press_key(VK_DOWN, temp);
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    cout << "thread: dodging stopped" << endl;
}

POINT get_tail(HDC& dc, POINT origin, int startx = 0, int starty = 0, int width = 700, int height = 200) {
    POINT p = { startx, starty };
    for (int i = startx; i < startx + width; i++) {//x
        for (int j = starty; j < starty + height; j++) {//y
            COLORREF color = GetPixel(dc, i, j);
            SetCursorPos(origin.x + i, origin.y + j);
            if (color == 5460819) {
                p = { i, j };
                return p;
            }
        }
    }
    return p;
}

int main() {
    HDC hdcMemory = NULL;
    POINT origin = {}, tail = {};//tail relative to origin
    int width = 350;
    int height = 200;
    int i = 0, j = 0, downtime = 320;
    POINT cactus_min = { 70, 8 };
    POINT cactus_max = { 130, 8 };
    POINT bird_coords = { 90, -20 };
    COLORREF threat_color = 5460819;
    COLORREF color = NULL;
    bool exit_flag = false;
    SHORT second_key = NULL;

    cout << "[N1] Get Map" << endl;
    cout << "[N2] Get Tail" << endl;
    cout << "[N3] Start Bot" << endl;
    cout << "[N4] Pixel Info" << endl;
    cout << "[N0] Stop | Exit" << endl;

    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        if (GetAsyncKeyState(VK_NUMPAD0)) { // Exit
            if (hdcMemory != NULL)
                DeleteDC(hdcMemory);
            return 0;
        }
        if (GetAsyncKeyState(VK_NUMPAD1)) { // get map
            GetCursorPos(&origin);
            get_Bitmap(origin.x, origin.y, hdcMemory, width, height);
            cout << "We got the map!" << endl;
        }
        if (GetAsyncKeyState(VK_NUMPAD2)) { // get tail
            POINT p;
            GetCursorPos(&p);
            tail = get_tail(hdcMemory, origin, p.x - origin.x, p.y - origin.y, 30, 30);
            cout << "Oh f*ck it's a t-rex!" << endl;
        }
        if (GetAsyncKeyState(VK_NUMPAD3)) {
            cout << "Starting Bot!" << endl;
            if (hdcMemory == NULL) {
                cout << "you did not find the map yet!";
            }
            else {
                int amount_speedups = 0;
                auto startTime = std::chrono::high_resolution_clock::now();
                auto endTime = std::chrono::high_resolution_clock::now();
                std::chrono::duration<double, std::milli> ms = (endTime - startTime);
                exit_flag = false;
                SetCursorPos(origin.x + tail.x + bird_coords.x, origin.y + bird_coords.y + tail.y);
                std::thread t_Bitmap(update_Bitmap, origin.x, origin.y, ref(hdcMemory), ref(exit_flag), width, height);
                std::thread t_Jumper(jumper, ref(exit_flag), tail, ref(cactus_min), ref(cactus_max), threat_color, ref(hdcMemory), ref(second_key), ref(downtime));
                std::thread t_Dodger(dodger, ref(exit_flag), tail, ref(bird_coords), threat_color, ref(hdcMemory));
                while (true) {
                    endTime = std::chrono::high_resolution_clock::now();
                    ms = (endTime - startTime);
                    if (ms.count() > 10000) {
                        amount_speedups++;
                        cout << "Speed++" << endl;
                        int addition = 7;
                        cactus_min.x += addition;
                        cactus_max.x += addition;
                        bird_coords.x += 4;
                        startTime = std::chrono::high_resolution_clock::now();
                        endTime = std::chrono::high_resolution_clock::now();
                    }
                    if (amount_speedups == 3) {
                        second_key = VK_DOWN;
                    }
                    if (amount_speedups == 9) {
                        downtime = 240;
                    }
                    if (amount_speedups == 11) {
                        downtime = 180;
                    }
                    if (GetAsyncKeyState(VK_NUMPAD0)) { // Exit
                        cout << "Stopping Bot!" << endl;
                        exit_flag = true;
                        t_Bitmap.join();
                        t_Jumper.join();
                        t_Dodger.join();
                        break;
                    }
                }
            }
        }
        if (GetAsyncKeyState(VK_NUMPAD4)) { // get pixel color
            POINT p;
            GetCursorPos(&p);
            if (hdcMemory != NULL) { // variable where hdc is stored
                COLORREF color = GetPixel(hdcMemory, p.x - origin.x, p.y - origin.y);
                cout << "Absolute values" << endl;
                cout << "X: " << p.x << " Y: " << p.y << " Color: " << color << endl;
                //cout << "Relative values" << endl; dont worry about this yet :P
                //cout << "X: " << p.x - origin.x - tail.x << " Y: " << p.y - (origin.y + tail.y) << endl;
            }
            else
                cout << "Get map first!" << endl;
        }
    }

}