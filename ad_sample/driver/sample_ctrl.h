
#ifndef SAMPLE_CTRL_H
#define SAMPLE_CTRL_H

#ifdef __cplusplus
extern "C"
{
#endif

    /***************************** Include Files ********************************/
#include "xil_types.h"

#define PT_PER_SAMPLE 8U
#define BYTE_PER_PT 2U
#define BYTE_PER_SAMPLE (PT_PER_SAMPLE * BYTE_PER_PT)

    typedef union sample_status_t
    {
        struct sample_ctrl
        {
            uint32_t move_done : 1;
            uint32_t move_err : 1;
            uint32_t move_busy : 1;
            uint32_t : 13;
            uint32_t sample_done : 1;
            uint32_t sample_err : 1;
            uint32_t sample_busy : 1;
            uint32_t : 13;
        } bit;
        uint32_t all;
    } sample_status_t;

    typedef struct sample_ctrl_t
    {
        uint32_t id;                    // 16'd0:
        uint32_t config_start_addr;     // 16'd4:
        uint32_t config_end_addr;       // 16'd8:
        uint32_t config_sample_num;     // 16'd12:
        uint32_t config_pre_sample_num; // 16'd16:
        uint32_t : 32;                  // 16'd20
        uint32_t : 32;                  // 16'd24
        uint32_t : 32;                  // 16'd28
        uint32_t update_config;         // 16'd32:
        uint32_t sample_reset;          // 16'd36:
        uint32_t sample_start;          // 16'd40:
        uint32_t sample_trig;           // 16'd44:
        uint32_t : 32;                  // 16'd48
        uint32_t : 32;                  // 16'd52
        uint32_t : 32;                  // 16'd56
        uint32_t : 32;                  // 16'd60
        sample_status_t sample_status;  // 16'd64:
        uint32_t rec_start_addr;        // 16'd68:
        uint32_t rec_end_addr;          // 16'd72:
        uint32_t rec_trig_addr;         // 16'd76:
        uint32_t move_addr;             // 16'd80:
    } sample_ctrl_t;

    extern int32_t sample(volatile sample_ctrl_t *handler, uint32_t stAddr, uint32_t bufferLen, uint32_t samplePt, uint32_t preSamplePt);

#ifdef __cplusplus
}
#endif

#endif
