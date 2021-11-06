
#define GF_MULT0_BASE_ADDR 0x1a400100
#include <stdint.h>
#include <hal/powerline_viterbi/viterbi.h>

void trigger_op(void);
void set_operands(uint8_t dataX, uint8_t dataY);
int poll_done(void);
uint8_t get_result(void);
uint8_t viterbi_hw(uint8_t dataX, uint8_t dataY);

