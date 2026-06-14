DefinitionBlock ("", "SSDT", 2, "LENOVO", "14WTPAD", 0x00000001)
{
    External (\_SB.I2CD, DeviceObj)

    Scope (\_SB.I2CD)
    {
        Device (TPDX)
        {
            Name (_HID, "ELAN0643")
            Name (_CID, "PNP0C50")
            Name (_STA, 0x0F)

            Name (_CRS, ResourceTemplate ()
            {
                I2cSerialBus (
                    0x0015,
                    ControllerInitiated,
                    400000,
                    AddressingMode7Bit,
                    "\\_SB.I2CD",
                    0x00,
                    ResourceConsumer
                )
                GpioInt (
                    Level,
                    ActiveLow,
                    ExclusiveAndWake,
                    PullUp,
                    0x0000,
                    "\\_SB.GPIO",
                    0x00,
                    ResourceConsumer,
                    ,
                )
                { 0x0009 }
            })

            Method (_DSM, 4, Serialized)
            {
                If ((Arg0 == ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de")))
                {
                    If ((Arg2 == Zero))
                    {
                        Return (Buffer (One) { 0x03 })
                    }

                    If ((Arg2 == One))
                    {
                        Return (One)
                    }
                }

                Return (Buffer (One) { 0x00 })
            }
        }
    }
}
