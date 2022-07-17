import util_compare_dicts


def test_flatten():
    assert util_compare_dicts.flatten({"x": 2, "y": {"z": 3}}) == {
        "x": 2, "y_z": 3}
    assert util_compare_dicts.flatten({"x": 2, "y": 3}) == {"x": 2, "y": 3}


def test_compare():
    assert util_compare_dicts.compare_dicts(
        {"x": "bar", "y": "baz"}, {"x": "bar", "y": "baz"}) == "pass"
    assert util_compare_dicts.compare_dicts(
        {"x": "bar", "y": {"z": "baz"}}, {"x": "bar", "y": {"z": "baz"}}) == "pass"

    assert util_compare_dicts.compare_dicts(
            {"x": "bar", "y": "baz"}, {"x": "bar", "y": "wrong"}) != "pass"
    assert util_compare_dicts.compare_dicts(
        {"x": "bar", "y": "baz"}, {"x": "bar", "y": 42}) != "pass"
    assert util_compare_dicts.compare_dicts(
        {"x": "bar", "y": {"z": "baz"}}, {"x": "bar", "y": {"z": "wrong"}}) != "pass"
