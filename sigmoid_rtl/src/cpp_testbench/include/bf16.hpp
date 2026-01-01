#pragma once

#include <bit>
#include <optional>
#include <sstream>

#include "helpers.hpp"

// bfloat16 helpers
namespace bf16 {
    static u16 fromFloat(float f) {
        auto floatBits = std::bit_cast<u32>(f);
        auto sign = (floatBits >> 31) & 0x1;
        auto exponent = (floatBits >> 23) & 0xFF;
        auto mantissa = floatBits & 0x7FFFFF;

        return u16((sign << 15) | (exponent << 7) | ((mantissa >> 16) & 0x7F));
    }

    static float toFloat(u16 bfloat) {
        auto sign = u32(bfloat >> 15);
        auto exponent = u32(bfloat >> 7) & 0xFF;
        auto mantissa = u32(bfloat & 0x7F);

        u32 floatBits = (sign << 31) | (exponent << 23) | (mantissa << 16);
        return std::bit_cast<float>(floatBits);
    }

    static u16 fromSignExpFrac(u16 sign, u16 exponent, u16 mantissa) {
        return u16((sign << 15) | (exponent << 7) | (mantissa & 0x7F));
    }

    static u16 sign(u16 bfloat) {
        return bfloat >> 15;
    }

    static u16 exponent(u16 bfloat) {
        return ((bfloat >> 7) & 0xFF);
    }

    static u16 mantissa(u16 bfloat) {
        return bfloat & 0x7F;
    }

    static bool isInf(u16 bfloat) {
        return exponent(bfloat) == 0xFF && mantissa(bfloat) == 0;
    }

    static bool isNAN(u16 bfloat) {
        return exponent(bfloat) == 0xFF && mantissa(bfloat) != 0;
    }

    static bool isSNAN(u16 bfloat) {
        return isNAN(bfloat) && ((bfloat & 0x40) == 0);
    }

    static bool isQNAN(u16 bfloat) {
        return isNAN(bfloat) && ((bfloat & 0x40) != 0);
    }

    static bool isDenormal(u16 bfloat) {
        return exponent(bfloat) == 0 && mantissa(bfloat) != 0;
    }

    static bool isZero(u16 bfloat) {
        return exponent(bfloat) == 0 && mantissa(bfloat) == 0;
    }

    static std::optional<u16> fromString(const std::string& str) {
        std::istringstream stream(str);

        // First, try parsing the input as a 16-bit hex value. If that fails, try parsing it as a float
        u16 hexValue;

        stream >> std::hex >> hexValue;
        if (!stream.fail() && stream.eof()) {
            return hexValue;
        } else {
            float floatValue;

            stream.clear();
            stream.str(str);
            stream >> floatValue;

            if (!stream.fail() && stream.eof()) {
                return bf16::fromFloat(floatValue);
            } else {
                return std::nullopt;
            }
        }
    }

    static std::optional<u16> fromString(const char* str) {
        return fromString(std::string(str));
    }
}  // namespace bf16
