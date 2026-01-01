#include <SDL.h>
#include <glad/gl.h>

#include "imgui_impl_sdl2.h"
#include "ui.hpp"

// Legacy function required so linking works
double sc_time_stamp() {
    return 0;
}

void stepCycles(Sigmoid* top, uint cycles) {
    while (cycles > 0) {
        top->clk = 0;
        top->eval();

        top->clk = 1;
        top->eval();

        cycles--;
    }
}

int main() {
    auto ctx = new VerilatedContext();
    auto top = new Sigmoid(ctx, "TOP");

    auto [window, glContext] = UI::init();

    // Reset
    top->rst = 1;
    top->valid_in = 0;
    stepCycles(top, 10);

    top->rst = 0;
    stepCycles(top, 10);

    bool done = false;
    while (!done) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            ImGui_ImplSDL2_ProcessEvent(&event);
            if (event.type == SDL_QUIT) done = true;
            if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
                done = true;
        }

        UI::startFrame();
        UI::drawTopModule(top);
        UI::drawPipeline(top);
        UI::endFrame(window);
    }

    UI::deinit(window, glContext);
    delete top;
    delete ctx;
}