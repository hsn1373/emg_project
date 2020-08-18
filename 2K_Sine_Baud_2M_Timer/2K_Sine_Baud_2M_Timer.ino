uint8_t channel_cnt = 16;
uint16_t value = 0;
byte data[] = {0x41, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00, 
0x00, 0x00, 0x00, 0x00};

void sendData()
{
  for(int i = 1; i < channel_cnt*2; i+=2){
    data[i] = ((int)(abs(sin(2*PI*(float)value/20000))*65535)) & 0xFF;
    data[i+1] = ((int)(abs(sin(2*PI*(float)value/20000))*65535)) >> 8;
  }
  value++;
  Serial.write(data, 1+(channel_cnt*2));
}

ISR(TIMER1_COMPA_vect){
   //interrupt commands for TIMER 1 here
   sendData();
}

void setup() {
  
  Serial.begin(2000000);

// TIMER 1 for interrupt frequency 2000 Hz:
cli(); // stop interrupts
TCCR1A = 0; // set entire TCCR1A register to 0
TCCR1B = 0; // same for TCCR1B
TCNT1  = 0; // initialize counter value to 0
// set compare match register for 2000 Hz increments
OCR1A = 7999; // = 16000000 / (1 * 2000) - 1 (must be <65536)
// turn on CTC mode
TCCR1B |= (1 << WGM12);
// Set CS12, CS11 and CS10 bits for 1 prescaler
TCCR1B |= (0 << CS12) | (0 << CS11) | (1 << CS10);
// enable timer compare interrupt
TIMSK1 |= (1 << OCIE1A);
sei(); // allow interrupts


}

void loop() {
  
}
