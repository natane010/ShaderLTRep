using UnityEngine;

public class LifeGameModel {

    public int Width {get; private set;}
    public int Height {get; private set;}

    public bool[] Cells {get;private set;}
    private bool[] prevCells;

    public LifeGameModel(int width, int height) {
        this.Width = width;
        this.Height = height;

        this.Cells = new bool[this.Width * this.Height];
        this.prevCells = new bool[this.Width * this.Height];

        // ランダマイズ
        for (var x = 0; x < this.Width; ++x) {
            for (var y = 0; y < this.Height; ++y) {
                this.Cells[y * this.Width + x] = Random.Range(0, 100) < 50;
            }
        }
    }

    private bool GetPrevCell(int x, int y) {
        if (x < 0) return false;
        if (y < 0) return false;

        if (x >= this.Width) return false;
        if (y >= this.Height) return false;

        return this.prevCells[y * this.Width + x];
    }

    public void Update() {
        this.Cells.CopyTo(prevCells, 0);

        for (var x = 0; x < this.Width; ++x) {
            for (var y = 0; y < this.Height; ++y) {
                // 隣接するセルの数を数える
                var adjoiningCellCount = 0;
                if (this.GetPrevCell(x - 1, y)) adjoiningCellCount++;
                if (this.GetPrevCell(x + 1, y)) adjoiningCellCount++;
                if (this.GetPrevCell(x, y - 1)) adjoiningCellCount++;
                if (this.GetPrevCell(x, y + 1)) adjoiningCellCount++;
                if (this.GetPrevCell(x - 1, y - 1)) adjoiningCellCount++;
                if (this.GetPrevCell(x + 1, y - 1)) adjoiningCellCount++;
                if (this.GetPrevCell(x - 1, y + 1)) adjoiningCellCount++;
                if (this.GetPrevCell(x + 1, y + 1)) adjoiningCellCount++;

                if (this.prevCells[y * this.Width + x]) {
                    // 過疎
                    if (adjoiningCellCount <= 1) {
                        this.Cells[y * this.Width + x] = false;
                    }

                    // 過密
                    if (adjoiningCellCount >= 4) {
                        this.Cells[y * this.Width + x] = false;
                    }
                } else {
                    // 誕生
                    if (adjoiningCellCount == 3) {
                        this.Cells[y * this.Width + x] = true;
                    }
                }
            }
        }
    }
}
