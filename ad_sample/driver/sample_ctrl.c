#include "sample_ctrl.h"
#include "xil_io.h"
#include "xstatus.h"

/**
 * @param handler 句柄
 * @param staddr 起始地址
 * @param bufferLen 缓冲区长度
 * @param bpp 每个采样点字节数
 * @param samplePt 总采样点数
 * @param preSamplePt 预采样点数
 */
int32_t sample(volatile sample_ctrl_t *handler, uint32_t stAddr, uint32_t bufferLen, uint32_t samplePt, uint32_t preSamplePt)
{
    if ((NULL == (void *)handler) || (0 == stAddr) || (samplePt * BYTE_PER_SAMPLE > bufferLen) || ((0xF7DEC7A5 != handler->id)))
    {
        return XST_INVALID_PARAM;
    }

    handler->sample_reset = 1U;
    while (handler->sample_reset)
        ;

    handler->config_start_addr = stAddr;
    handler->config_end_addr = stAddr + bufferLen - 1U;
    handler->config_sample_num = samplePt;
    handler->config_pre_sample_num = preSamplePt;

    handler->update_config = 0x01;
    while (handler->update_config)
        ;

    handler->sample_start = 0x01;
    while (handler->sample_start)
        ;

    handler->sample_trig = 0x01;
    handler->sample_trig = 0x00;

    while (!(handler->sample_status.bit.sample_done || handler->sample_status.bit.sample_err || handler->sample_status.bit.move_err))
        ;

    return XST_SUCCESS;
}
