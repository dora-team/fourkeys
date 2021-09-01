if (json) {
    return JSON.parse(json).map(x=>JSON.stringify(x));
} else {
    return [];
}