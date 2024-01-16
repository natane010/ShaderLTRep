using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class LifeGameView : MonoBehaviour {

    LifeGameModel model;
    Texture2D texture;
    Color[] pixels;

    void Start () {
        this.model = new LifeGameModel(3840, 2160);
        this.pixels = new Color[this.model.Width * this.model.Height];

        this.texture = new Texture2D(this.model.Width, this.model.Height, TextureFormat.ARGB32, false, false);
        this.texture.filterMode = FilterMode.Point;

        var meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.material.SetTexture("_MainTex", this.texture);
    }

    void Update () {
        this.model.Update();
        var cells = this.model.Cells;

        for (var x = 0; x < this.model.Width; ++x) {
            for (var y = 0; y < this.model.Height; ++y) {
                this.pixels[y * this.model.Width + x] = cells[y * this.model.Width + x] ? Color.white : Color.gray;
            }
        }

        this.texture.SetPixels(this.pixels);
        this.texture.Apply();
    }
}
