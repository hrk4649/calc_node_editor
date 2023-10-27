extends Node
class_name Func2

func _init():
    test_round()

func test_round():
    assert_round(12345, 0, null)
    assert_round(12345, 1000, 12000)
    assert_round(12345, 100, 12300)
    assert_round(12345, 10, 12350)
    assert_round(12345, 1, 12345)
    assert_round(12345.67, 0.1, 12345.7)
    assert_round(-12344, 10, -12340)
    assert_round(-12345, 10, -12350)

func assert_round(a, b, expected):
    var result = func2_round(a, b)
    assert(result == expected,
        "round(%s, %s) is expected to %s but %s" % [a, b, expected, result])

func func2_round(value_a, value_b):
    if value_b == 0:
        print("process_node_func2:round(): value_b is 0")
        return null
#            if input_value_b % 10 != 0:
#                print("process_node_func2:round(): input value b %s is expected power of 10" % input_value_b)
#                return
    var value1 = float(value_a) / value_b
    var value2 = round(value1)
    var value3 = value2 * value_b
    return value3
