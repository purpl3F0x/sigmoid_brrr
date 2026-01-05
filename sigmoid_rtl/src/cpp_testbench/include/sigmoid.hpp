#pragma once

#include "helpers.hpp"
#include "sigmoid_t.h"
#include "sigmoid_t___024root.h"

using Sigmoid = sigmoid_t;
static constexpr u32 PIPELINE_STAGES = 6;

void stepCycles(Sigmoid* top, uint cycles);