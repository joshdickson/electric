import { useLiveQuery } from "electric-sql/react";
import React, { useEffect } from "react";
import { Image, Pressable, Text, View } from "react-native";
import { Foods as Food } from "./generated/client";

import { useElectric } from "./ElectricProvider";
import { styles } from "./styles";

export const Example = () => {
  const { db } = useElectric()!;
  const { results } = useLiveQuery(db.foods.liveMany());

  useEffect(() => {
    const syncItems = async () => {
      // Resolves when the shape subscription has been established.
      const shape = await db.foods.sync();

      // Resolves when the data has been synced into the local database.
      await shape.synced;
    };

    syncItems();
  }, []);

  const addItem = async () => {
    await db.foods.create({
      data: {
        id: "id_001",
        name: "Name",
        type: "Type",
        serving_quantity_common: 1,
        serving_unit_common: "unit",
        serving_quantity_metric: 1,
        serving_unit_metric: "g",
        nutrition: {
          calories: 100,
          protein: 10,
          fat: 10,
          carbs: 10,
        },
        created_at: new Date(),
        updated_at: new Date(),
      },
    });
  };

  const clearItems = async () => {
    await db.foods.deleteMany();
  };

  const items: Food[] = results ?? [];

  return (
    <View>
      <View style={styles.iconContainer}>
        <Image source={require("../assets/icon.png")} />
      </View>
      <View style={styles.buttons}>
        <Pressable style={styles.button} onPress={addItem}>
          <Text style={styles.text}>Add</Text>
        </Pressable>
        <Pressable style={styles.button} onPress={clearItems}>
          <Text style={styles.text}>Clear</Text>
        </Pressable>
      </View>
      <View style={styles.items}>
        {items.map((item: Food, index: number) => (
          <Text key={index} style={styles.item}>
            {item.name}
          </Text>
        ))}
      </View>
    </View>
  );
};
