#include <hal/powerline_viterbi/viterbi_driver.h>
#include <stdint.h>
#include <stdio.h>

//#define check_ip

void trigger_op(void){
uint32_t volatile *ctrl1_reg = (uint32_t *) VITERBI_CTRL1(0);
asm volatile("": : : "memory"); // stop the compiler from optimize to much
*ctrl1_reg = 1 ;
asm volatile("": : : "memory"); // prevent that the trigger is set before all data arived
}

void set_operands(uint8_t dataX, uint8_t dataY)
{
  uint32_t volatile*  data_X_reg_start = (uint32_t*)VITERBI_DATAX(0);
  uint32_t volatile*  data_Y_reg_start = (uint32_t*)VITERBI_DATAY(0);
  //Make sure we are in idle state before changing the operands

    *data_X_reg_start = (uint32_t) dataX;
    *data_Y_reg_start = (uint32_t) dataY;  
}

int poll_done(void)
{
  uint32_t volatile * status_reg = (uint32_t*)VITERBI_VALID(0);
  uint32_t current_status;
  do {
    current_status = *status_reg&0x1; // mask bit 0
  } while(current_status == 1);
  if (current_status == 0)
    return 0;
  else
    return current_status;
}

uint8_t get_result(void)
{
  uint32_t volatile* result_reg_start = (uint32_t*)VITERBI_BITOUT(0);
  	
    uint8_t result = (uint8_t) (*result_reg_start & 0x1);  	
    return result;
  
}
uint8_t viterbi_hw(uint8_t dataX, uint8_t dataY)
{

#ifdef check_ip
	int status = poll_done();
	if (status != 0) {		// check if the IP is ready
		printf("IP stuck: %i\n",status);
		return status;
	}
#endif
 	set_operands(dataX,dataY);		

 	trigger_op();
#ifdef check_ip
 	status = poll_done();


	if (status != 0) {		// check if the IP is ready
		printf("operation failed!\n");
		return status;
	}
	else
	{
#endif
	 return get_result();
#ifdef check_ip
	}
#endif

}

