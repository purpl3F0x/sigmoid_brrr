#pragma once

#include <SDL.h>

#include <utility>

#include "sigmoid.hpp"

namespace UI {
    std::pair<SDL_Window*, SDL_GLContext> init();
    void deinit(SDL_Window* window, SDL_GLContext glContext);

    void startFrame();
    void endFrame(SDL_Window* window);

    void drawTopModule(Sigmoid* top);
    void drawPipeline(Sigmoid* top);

    // Draw each pipeline stage
    void drawStage0(Sigmoid* top);
    void drawStage1(Sigmoid* top);
    void drawStage2(Sigmoid* top);
    void drawStage3(Sigmoid* top);
    void drawStage4(Sigmoid* top);
    void drawStage5(Sigmoid* top);
}  // namespace UI