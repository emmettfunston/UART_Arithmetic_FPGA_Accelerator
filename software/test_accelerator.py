import random
import serial

PORT = "COM4"
BAUD = 115200


def calculate(fpga, a, b, op):
    if not (0 <= a <= 255 and 0 <= b <= 255):
        raise ValueError("Operands must be unsigned 8-bit integers")
    if op not in ("+", "*"):
        raise ValueError("Operation must be '+' or '*'")

    opcode = 0x01 if op == "+" else 0x02
    command = bytes([opcode, a, b])
    fpga.reset_input_buffer()
    fpga.write(command)
    fpga.flush()
    response = fpga.read(2)
    if len(response) != 2:
        raise TimeoutError(f"Expected 2 bytes, received {len(response)}")
    return int.from_bytes(response, "little")


def main():
    tests = [
        (12, 7, "*"),
        (12, 7, "+"),
        (255, 255, "*"),
        (255, 255, "+"),
        (0, 100, "*"),
        (23, 42, "+"),
    ]
    random.seed(42)
    for _ in range(100):
        a = random.randint(0, 255)
        b = random.randint(0, 255)
        op = random.choice(["+", "*"])
        tests.append((a, b, op))

    passed = 0
    with serial.Serial(PORT, BAUD, timeout=2) as fpga:
        for a, b, op in tests:
            try:
                actual = calculate(fpga, a, b, op)
            except TimeoutError as exc:
                print(f"FAIL: {a} {op} {b}: {exc}")
                continue
            expected = a + b if op == "+" else a * b
            if actual == expected:
                passed += 1
            else:
                print(f"FAIL: {a} {op} {b} = {actual}, expected {expected}")
    print(f"Passed {passed}/{len(tests)} hardware tests")
    if passed != len(tests):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
