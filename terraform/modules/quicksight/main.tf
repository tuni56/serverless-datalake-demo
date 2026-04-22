data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# IAM Role para QuickSight acceder a S3 y Athena
resource "aws_iam_role" "quicksight" {
  name = "${var.project_name}-quicksight-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "quicksight.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "quicksight" {
  name = "${var.project_name}-quicksight-policy-${var.environment}"
  role = aws_iam_role.quicksight.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.curated_bucket_arn,
          "${var.curated_bucket_arn}/*",
          "arn:aws:s3:::${var.athena_results_bucket_name}",
          "arn:aws:s3:::${var.athena_results_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.athena_results_bucket_name}",
          "arn:aws:s3:::${var.athena_results_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "athena:GetWorkGroup"
        ]
        Resource = "arn:aws:athena:${local.region}:${local.account_id}:workgroup/${var.athena_workgroup_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${local.region}:${local.account_id}:catalog",
          "arn:aws:glue:${local.region}:${local.account_id}:database/${var.glue_database_name}",
          "arn:aws:glue:${local.region}:${local.account_id}:table/${var.glue_database_name}/*"
        ]
      }
    ]
  })
}

# Permisos S3 para el service role de QuickSight
resource "aws_iam_role_policy" "quicksight_service_s3" {
  name = "${var.project_name}-quicksight-s3-${var.environment}"
  role = "aws-quicksight-service-role-v0"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.curated_bucket_arn,
          "${var.curated_bucket_arn}/*",
          "arn:aws:s3:::${var.athena_results_bucket_name}",
          "arn:aws:s3:::${var.athena_results_bucket_name}/*"
        ]
      }
    ]
  })
}

# QuickSight Data Source (Athena)
resource "aws_quicksight_data_source" "athena" {
  aws_account_id = local.account_id
  data_source_id = "${var.project_name}-athena-${var.environment}"
  name           = "E-commerce Data Lake (${var.environment})"
  type           = "ATHENA"

  parameters {
    athena {
      work_group = var.athena_workgroup_name
    }
  }

  permission {
    principal = "arn:aws:quicksight:${local.region}:${local.account_id}:user/default/${var.quicksight_user}"
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.quicksight_service_s3]
}

locals {
  qs_principal = "arn:aws:quicksight:${local.region}:${local.account_id}:user/default/${var.quicksight_user}"
  ds_actions = [
    "quicksight:DescribeDataSet",
    "quicksight:DescribeDataSetPermissions",
    "quicksight:PassDataSet",
    "quicksight:UpdateDataSet",
    "quicksight:DeleteDataSet",
    "quicksight:UpdateDataSetPermissions",
    "quicksight:DescribeIngestion",
    "quicksight:ListIngestions",
    "quicksight:CreateIngestion",
    "quicksight:CancelIngestion"
  ]
}

# Dataset: Orders (join con customers y products)
resource "aws_quicksight_data_set" "sales" {
  aws_account_id = local.account_id
  data_set_id    = "${var.project_name}-sales-${var.environment}"
  name           = "Sales Analytics (${var.environment})"
  import_mode    = "DIRECT_QUERY"

  physical_table_map {
    physical_table_map_id = "orders"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.athena.arn
      name            = "sales_joined"
      sql_query       = <<-SQL
        SELECT
          o.order_id,
          o.order_date,
          o.quantity,
          o.total_amount,
          o.status,
          c.name AS customer_name,
          c.country,
          p.name AS product_name,
          p.category,
          p.price AS unit_price
        FROM "${var.glue_database_name}"."orders" o
        LEFT JOIN "${var.glue_database_name}"."customers" c ON o.customer_id = c.customer_id
        LEFT JOIN "${var.glue_database_name}"."products" p ON o.product_id = p.product_id
      SQL
      columns {
        name = "order_id"
        type = "INTEGER"
      }
      columns {
        name = "order_date"
        type = "DATETIME"
      }
      columns {
        name = "quantity"
        type = "INTEGER"
      }
      columns {
        name = "total_amount"
        type = "DECIMAL"
      }
      columns {
        name = "status"
        type = "STRING"
      }
      columns {
        name = "customer_name"
        type = "STRING"
      }
      columns {
        name = "country"
        type = "STRING"
      }
      columns {
        name = "product_name"
        type = "STRING"
      }
      columns {
        name = "category"
        type = "STRING"
      }
      columns {
        name = "unit_price"
        type = "DECIMAL"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "sales"
    alias                = "Sales"
    source {
      physical_table_id = "orders"
    }
  }

  permissions {
    principal = local.qs_principal
    actions   = local.ds_actions
  }
}

# Analysis (base para el dashboard)
resource "aws_quicksight_analysis" "ecommerce" {
  aws_account_id = local.account_id
  analysis_id    = "${var.project_name}-analysis-${var.environment}"
  name           = "E-commerce Analytics (${var.environment})"

  definition {
    data_set_identifiers_declarations {
      identifier   = "sales"
      data_set_arn = aws_quicksight_data_set.sales.arn
    }

    sheets {
      sheet_id = "overview"
      name     = "Sales Overview"

      visuals {
        bar_chart_visual {
          visual_id = "sales-by-category"
          title {
            visibility = "VISIBLE"
            format_text { plain_text = "Ventas por Categoría" }
          }
          chart_configuration {
            field_wells {
              bar_chart_aggregated_field_wells {
                category {
                  categorical_dimension_field {
                    field_id = "category"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "category"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "total_amount_sum"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "total_amount"
                    }
                    aggregation_function { simple_numerical_aggregation = "SUM" }
                  }
                }
              }
            }
            orientation = "HORIZONTAL"
          }
        }
      }

      visuals {
        line_chart_visual {
          visual_id = "sales-trend"
          title {
            visibility = "VISIBLE"
            format_text { plain_text = "Tendencia de Ventas Mensual" }
          }
          chart_configuration {
            field_wells {
              line_chart_aggregated_field_wells {
                category {
                  date_dimension_field {
                    field_id = "order_date"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "order_date"
                    }
                    date_granularity = "MONTH"
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "revenue"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "total_amount"
                    }
                    aggregation_function { simple_numerical_aggregation = "SUM" }
                  }
                }
              }
            }
          }
        }
      }

      visuals {
        pie_chart_visual {
          visual_id = "orders-by-country"
          title {
            visibility = "VISIBLE"
            format_text { plain_text = "Pedidos por País" }
          }
          chart_configuration {
            field_wells {
              pie_chart_aggregated_field_wells {
                category {
                  categorical_dimension_field {
                    field_id = "country"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "country"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "order_count"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "order_id"
                    }
                    aggregation_function { simple_numerical_aggregation = "DISTINCT_COUNT" }
                  }
                }
              }
            }
          }
        }
      }

      visuals {
        kpi_visual {
          visual_id = "total-revenue"
          title {
            visibility = "VISIBLE"
            format_text { plain_text = "Revenue Total" }
          }
          chart_configuration {
            field_wells {
              values {
                numerical_measure_field {
                  field_id = "kpi_revenue"
                  column {
                      data_set_identifier = "sales"
                      column_name         = "total_amount"
                    }
                  aggregation_function { simple_numerical_aggregation = "SUM" }
                }
              }
            }
          }
        }
      }

      visuals {
        table_visual {
          visual_id = "top-products"
          title {
            visibility = "VISIBLE"
            format_text { plain_text = "Top Productos por Ingresos" }
          }
          chart_configuration {
            field_wells {
              table_aggregated_field_wells {
                group_by {
                  categorical_dimension_field {
                    field_id = "product"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "product_name"
                    }
                  }
                }
                group_by {
                  categorical_dimension_field {
                    field_id = "cat"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "category"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "prod_revenue"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "total_amount"
                    }
                    aggregation_function { simple_numerical_aggregation = "SUM" }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "prod_qty"
                    column {
                      data_set_identifier = "sales"
                      column_name         = "quantity"
                    }
                    aggregation_function { simple_numerical_aggregation = "SUM" }
                  }
                }
              }
            }
            sort_configuration {
              row_sort {
                field_sort {
                  field_id  = "prod_revenue"
                  direction = "DESC"
                }
              }
            }
          }
        }
      }
    }
  }

  permissions {
    principal = local.qs_principal
    actions = [
      "quicksight:DescribeAnalysis",
      "quicksight:DescribeAnalysisPermissions",
      "quicksight:UpdateAnalysis",
      "quicksight:UpdateAnalysisPermissions",
      "quicksight:DeleteAnalysis",
      "quicksight:QueryAnalysis",
      "quicksight:RestoreAnalysis"
    ]
  }
}

# Dashboard publicado desde el analysis
resource "aws_quicksight_dashboard" "ecommerce" {
  aws_account_id = local.account_id
  dashboard_id   = "${var.project_name}-dashboard-${var.environment}"
  name           = "E-commerce Dashboard (${var.environment})"
  version_description = "v1"

  source_entity {
    source_template {
      arn = aws_quicksight_template.ecommerce.arn
      data_set_references {
        data_set_arn         = aws_quicksight_data_set.sales.arn
        data_set_placeholder = "sales"
      }
    }
  }

  permissions {
    principal = local.qs_principal
    actions = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:UpdateDashboardPermissions",
      "quicksight:QueryDashboard",
      "quicksight:UpdateDashboard",
      "quicksight:DeleteDashboard",
      "quicksight:UpdateDashboardPublishedVersion",
      "quicksight:DescribeDashboardPermissions"
    ]
  }
}

# Template (puente entre analysis y dashboard)
resource "aws_quicksight_template" "ecommerce" {
  aws_account_id = local.account_id
  template_id    = "${var.project_name}-template-${var.environment}"
  name           = "E-commerce Template (${var.environment})"
  version_description = "v1"

  source_entity {
    source_analysis {
      arn = aws_quicksight_analysis.ecommerce.arn
      data_set_references {
        data_set_arn         = aws_quicksight_data_set.sales.arn
        data_set_placeholder = "sales"
      }
    }
  }

  permissions {
    principal = local.qs_principal
    actions = [
      "quicksight:DescribeTemplate",
      "quicksight:UpdateTemplate"
    ]
  }
}
